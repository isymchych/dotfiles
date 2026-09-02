import assert from "node:assert/strict";
import test from "node:test";

import { parseLauncherArgs } from "./launcher-args.ts";

test("parses leading launcher modifiers", () => {
  assert.deepEqual(parseLauncherArgs(["account", "help", "--model", "gpt-5"]), {
    passthrough: ["--model", "gpt-5"],
    showHelp: true,
    useAccountSwitcher: true,
  });
});

test("preserves removed launcher modifiers as Pi arguments", () => {
  assert.deepEqual(parseLauncherArgs(["mcp", "tilth"]), {
    passthrough: ["mcp", "tilth"],
    showHelp: false,
    useAccountSwitcher: false,
  });
});

test("preserves modifier-like values after Pi arguments", () => {
  assert.deepEqual(parseLauncherArgs(["--name", "account", "help"]), {
    passthrough: ["--name", "account", "help"],
    showHelp: false,
    useAccountSwitcher: false,
  });
});

test("preserves arguments after the Pi delimiter", () => {
  assert.deepEqual(parseLauncherArgs(["--", "account"]), {
    passthrough: ["--", "account"],
    showHelp: false,
    useAccountSwitcher: false,
  });
});
