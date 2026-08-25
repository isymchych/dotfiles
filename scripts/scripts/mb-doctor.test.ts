import assert from "node:assert/strict";
import test from "node:test";

import type { CommandResult } from "@accel-os/shared/process";

import {
  formatDoctorResults,
  runDoctor,
  type DoctorContext,
  type DoctorDependencies,
} from "../lib/doctor.ts";
import { resolveHostState, type HostConfig, type ResolvedHostState } from "../lib/host-config.ts";

function commandResult(code: number, stdout = "", stderr = ""): CommandResult {
  return { code, stdout, stderr, success: code === 0 };
}

const state: ResolvedHostState = {
  hostname: "test-host",
  features: [],
  packages: ["base-package"],
  services: {
    system: {
      enabled: ["required.service"],
      disabled: ["conflicting.service"],
    },
    user: {
      enabled: ["required-user.service"],
      disabled: [],
    },
  },
};

const context: DoctorContext = {
  state,
  repositoryRoot: "/repo",
  homeDirectory: "/home/test",
  username: "test",
  platform: "linux",
  environment: {},
};

const validFiles = new Map([
  ["/etc/os-release", "NAME=Arch Linux\nID=arch\n"],
  [
    "/etc/systemd/logind.conf.d/80-accel-os.conf",
    "# Managed by accel-os.\n[Login]\nKillUserProcesses=yes\nHandlePowerKey=suspend\n",
  ],
  ["/etc/sysctl.d/80-accel-os.conf", "# Managed by accel-os.\nvm.swappiness = 10\n"],
  ["/etc/nsswitch.conf", "passwd: files\nhosts: mymachines files myhostname dns\n"],
]);

test("resolveHostState selects feature packages and convergent service states", () => {
  const config: HostConfig = {
    packages: {
      packages: {
        linux: {
          arch: {
            pacman: {
              base: { system: ["base-package"] },
              features: {
                selected: { packages: ["selected-package"] },
                unselected: { packages: ["unselected-package"] },
              },
            },
            aur: { base: {}, features: {} },
          },
        },
      },
    },
    services: {
      services: {
        linux: {
          arch: {
            base: {
              system: { enabled: ["base.service"], disabled: ["disabled.service"] },
              user: { enabled: [], disabled: ["disabled-user.service"] },
            },
            features: {
              selected: {
                system: {
                  enabled: ["selected.service"],
                  disabled: ["selected-disabled.service"],
                },
                user: { enabled: ["selected-user.service"] },
              },
              unselected: {
                system: { enabled: ["unselected.service"] },
                user: { enabled: ["unselected-user.service"] },
              },
            },
          },
        },
      },
    },
    hosts: {
      hosts: {
        "test-host": { features: ["selected"] },
      },
    },
    tlp: { tlp: { hosts: {} } },
  };

  assert.deepEqual(resolveHostState(config, "test-host"), {
    hostname: "test-host",
    features: ["selected"],
    packages: ["base-package", "selected-package"],
    services: {
      system: {
        enabled: ["base.service", "selected.service"],
        disabled: ["disabled.service", "selected-disabled.service", "unselected.service"],
      },
      user: {
        enabled: ["selected-user.service"],
        disabled: ["disabled-user.service", "unselected-user.service"],
      },
    },
  });
});

test("resolveHostState applies only baseline service state to an undeclared host", () => {
  const config: HostConfig = {
    packages: {
      packages: {
        linux: {
          arch: {
            pacman: {
              base: { system: ["base-package"] },
              features: { optional: { packages: ["optional-package"] } },
            },
            aur: { base: {}, features: {} },
          },
        },
      },
    },
    services: {
      services: {
        linux: {
          arch: {
            base: {
              system: { enabled: ["base.service"], disabled: ["base-disabled.service"] },
              user: { enabled: [], disabled: ["base-disabled-user.service"] },
            },
            features: {
              optional: {
                system: { enabled: ["optional.service"] },
                user: { enabled: ["optional-user.service"] },
              },
            },
          },
        },
      },
    },
    hosts: { hosts: {} },
    tlp: { tlp: { hosts: {} } },
  };

  assert.deepEqual(resolveHostState(config, "undeclared-host"), {
    hostname: "undeclared-host",
    features: [],
    packages: ["base-package"],
    services: {
      system: {
        enabled: ["base.service"],
        disabled: ["base-disabled.service"],
      },
      user: {
        enabled: [],
        disabled: ["base-disabled-user.service"],
      },
    },
  });
});

function createDependencies(overrides: Partial<DoctorDependencies> = {}): DoctorDependencies {
  const dependencies: DoctorDependencies = {
    async readText(filePath) {
      return validFiles.get(filePath) ?? null;
    },
    async inspectPath(filePath) {
      return {
        uid: 0,
        gid: 0,
        mode: filePath === "/usr/local/bin/run-sway.sh" ? 0o100755 : 0o100644,
        isFile: true,
        isSymbolicLink: false,
      };
    },
    async listFiles(directory) {
      assert.equal(directory, "/repo/dotfiles/bin");
      return ["executable_mb-doctor"];
    },
    async isExecutable(filePath) {
      return filePath === "/home/test/bin/mb-doctor" || filePath === "/home/test/bin/accel-node";
    },
    async runCommand(command, args) {
      if (command === "pacman") {
        return commandResult(0, "base-package");
      }
      if (command === "/home/test/bin/accel-node") {
        return commandResult(0, "v24.0.0");
      }
      if (command !== "systemctl") {
        throw new Error(`Unexpected command: ${command}`);
      }
      if (args.join(" ") === "--user show-environment") {
        return commandResult(0);
      }
      if (args.includes("is-active")) {
        const service = args.at(-1);
        if (service === "required.service" || service === "required-user.service") {
          return commandResult(0, "active");
        }
        if (service === "conflicting.service") {
          return commandResult(3, "inactive");
        }
      }
      const service = args.at(-1);
      if (service === "required.service" || service === "required-user.service") {
        return commandResult(0, "enabled");
      }
      if (service === "conflicting.service") {
        return commandResult(1, "disabled");
      }
      throw new Error(`Unexpected systemctl arguments: ${args.join(" ")}`);
    },
  };

  return { ...dependencies, ...overrides };
}

test("runDoctor passes when the declared host state is satisfied", async () => {
  const results = await runDoctor(context, createDependencies());

  assert.deepEqual(
    results.map(({ id, status }) => ({ id, status })),
    [
      { id: "host", status: "pass" },
      { id: "packages", status: "pass" },
      { id: "system-services", status: "pass" },
      { id: "user-services", status: "pass" },
      { id: "managed-config", status: "pass" },
      { id: "script-runtime", status: "pass" },
    ],
  );
});

test("runDoctor aggregates missing packages and managed configuration drift", async () => {
  const dependencies = createDependencies({
    async readText(filePath) {
      if (filePath === "/etc/sysctl.d/80-accel-os.conf") {
        return null;
      }
      return validFiles.get(filePath) ?? null;
    },
    async runCommand(command, args, options) {
      if (command === "pacman") {
        return commandResult(0);
      }
      return createDependencies().runCommand(command, args, options);
    },
  });

  const results = await runDoctor(context, dependencies);
  const packages = results.find((result) => result.id === "packages");
  const managedConfig = results.find((result) => result.id === "managed-config");

  assert.ok(packages);
  assert.equal(packages.status, "fail");
  assert.deepEqual(packages.details, ["base-package"]);
  assert.ok(managedConfig);
  assert.equal(managedConfig.status, "fail");
  assert.match(managedConfig.details?.join("\n") ?? "", /80-accel-os\.conf: missing/u);
});

test("runDoctor skips user services when the user manager is unavailable", async () => {
  const base = createDependencies();
  const dependencies = createDependencies({
    async runCommand(command, args, options) {
      if (command === "systemctl" && args.join(" ") === "--user show-environment") {
        return commandResult(1, "", "Failed to connect to bus");
      }
      return base.runCommand(command, args, options);
    },
  });

  const results = await runDoctor(context, dependencies);
  const userServices = results.find((result) => result.id === "user-services");

  assert.ok(userServices);
  assert.equal(userServices.status, "skip");
  assert.deepEqual(userServices.details, ["Failed to connect to bus"]);
});

test("runDoctor checks persistent and runtime service state", async () => {
  const base = createDependencies();
  const dependencies = createDependencies({
    async runCommand(command, args, options) {
      if (command === "systemctl" && args.at(-1) === "required.service") {
        if (args.includes("is-enabled")) {
          return commandResult(0, "enabled-runtime");
        }
        if (args.includes("is-active")) {
          return commandResult(3, "inactive");
        }
      }
      if (command === "systemctl" && args.at(-1) === "conflicting.service") {
        if (args.includes("is-enabled")) {
          return commandResult(1, "disabled");
        }
        if (args.includes("is-active")) {
          return commandResult(0, "active");
        }
      }
      return base.runCommand(command, args, options);
    },
  });

  const results = await runDoctor(context, dependencies);
  const systemServices = results.find((result) => result.id === "system-services");

  assert.ok(systemServices);
  assert.equal(systemServices.status, "fail");
  assert.deepEqual(systemServices.details, [
    "required.service: expected enabled, found enabled-runtime",
    "required.service: expected active, found inactive",
    "conflicting.service: expected inactive, found active",
  ]);
});

test("runDoctor rejects conflicting duplicate managed settings", async () => {
  const tlpContext: DoctorContext = {
    ...context,
    state: {
      ...state,
      tlp: {
        chargeThresholds: {
          battery: "BAT0",
          start: 75,
          stop: 80,
        },
      },
    },
  };
  const dependencies = createDependencies({
    async readText(filePath) {
      if (filePath === "/etc/tlp.d/01-accel-os.conf") {
        return [
          "START_CHARGE_THRESH_BAT0=75",
          "STOP_CHARGE_THRESH_BAT0=80",
          "STOP_CHARGE_THRESH_BAT0=100",
          "",
        ].join("\n");
      }
      return validFiles.get(filePath) ?? null;
    },
  });

  const results = await runDoctor(tlpContext, dependencies);
  const managedConfig = results.find((result) => result.id === "managed-config");

  assert.ok(managedConfig);
  assert.equal(managedConfig.status, "fail");
  assert.match(managedConfig.details?.join("\n") ?? "", /tlp.*contents differ/u);
});

test("runDoctor detects stale managed feature configuration", async () => {
  const dependencies = createDependencies({
    async readText(filePath) {
      if (filePath === "/etc/vconsole.conf") {
        return "# BEGIN accel-os console font\nFONT=ter-124n\n# END accel-os console font\n";
      }
      if (filePath === "/usr/local/bin/run-sway.sh") {
        return "#!/usr/bin/env zsh\n# Managed by accel-os.\n";
      }
      if (filePath === "/etc/greetd/config.toml") {
        return "# Managed by accel-os.\n";
      }
      return validFiles.get(filePath) ?? null;
    },
  });

  const results = await runDoctor(context, dependencies);
  const managedConfig = results.find((result) => result.id === "managed-config");
  const details = managedConfig?.details?.join("\n") ?? "";

  assert.ok(managedConfig);
  assert.equal(managedConfig.status, "fail");
  assert.match(details, /stale managed console font block/u);
  assert.match(details, /run-sway\.sh: stale configuration/u);
  assert.match(details, /greetd\/config\.toml: stale configuration/u);
});

test("runDoctor verifies the greetd configuration and file metadata", async () => {
  const swayContext: DoctorContext = {
    ...context,
    state: {
      ...state,
      features: ["sway"],
      greetd: { autologin: true },
    },
  };
  const dependencies = createDependencies({
    async readText(filePath) {
      if (filePath === "/usr/local/bin/run-sway.sh") {
        return '#!/usr/bin/env zsh\n# Managed by accel-os.\n\nsource "$HOME/.run-sway"\n';
      }
      if (filePath === "/etc/greetd/config.toml") {
        return [
          "# Managed by accel-os.",
          "",
          "[terminal]",
          "vt = 1",
          "",
          "[default_session]",
          'command = "agreety --cmd /usr/local/bin/run-sway.sh"',
          'user = "greeter"',
          "",
          "[initial_session]",
          'command = "/usr/local/bin/wrong-session.sh"',
          'user = "test"',
          "",
        ].join("\n");
      }
      return validFiles.get(filePath) ?? null;
    },
    async inspectPath(filePath) {
      if (filePath === "/usr/local/bin/run-sway.sh") {
        return {
          uid: 1000,
          gid: 1000,
          mode: 0o100777,
          isFile: true,
          isSymbolicLink: false,
        };
      }
      return {
        uid: 0,
        gid: 0,
        mode: 0o100644,
        isFile: true,
        isSymbolicLink: false,
      };
    },
  });

  const results = await runDoctor(swayContext, dependencies);
  const managedConfig = results.find((result) => result.id === "managed-config");
  const details = managedConfig?.details?.join("\n") ?? "";

  assert.ok(managedConfig);
  assert.equal(managedConfig.status, "fail");
  assert.match(details, /greetd\/config\.toml: contents differ/u);
  assert.match(details, /run-sway\.sh: expected root:root ownership/u);
  assert.match(details, /run-sway\.sh: expected mode 0755, found 0777/u);
});

test("formatDoctorResults includes details, remediation, and totals", () => {
  const output = formatDoctorResults([
    { id: "host", status: "pass", summary: "test-host" },
    {
      id: "packages",
      status: "fail",
      summary: "one missing",
      details: ["missing-package"],
      remediation: "Run: chezmoi apply",
    },
    { id: "user-services", status: "skip", summary: "manager unavailable" },
  ]);

  assert.match(output, /^PASS host: test-host/mu);
  assert.match(output, /^FAIL packages: one missing/mu);
  assert.match(output, /^ {5}missing-package$/mu);
  assert.match(output, /1 passed, 1 skipped, 1 failed\n$/u);
});
