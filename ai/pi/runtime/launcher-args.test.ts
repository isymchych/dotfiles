import assert from "node:assert/strict";
import test from "node:test";

import { parseLauncherArgs } from "./launcher-args.ts";

test("parses leading launcher modifiers", () => {
  assert.deepEqual(parseLauncherArgs(["tilth", "mcp", "--model", "gpt-5"]), {
    passthrough: ["--model", "gpt-5"],
    showHelp: false,
    useAccountSwitcher: false,
    useMcp: true,
    useTilth: true,
  });
});

test("preserves a Pi option value named tilth", () => {
  assert.deepEqual(parseLauncherArgs(["--name", "tilth"]), {
    passthrough: ["--name", "tilth"],
    showHelp: false,
    useAccountSwitcher: false,
    useMcp: false,
    useTilth: false,
  });
});

test("preserves modifier-like values after Pi arguments", () => {
  assert.deepEqual(parseLauncherArgs(["--name", "tilth", "mcp"]), {
    passthrough: ["--name", "tilth", "mcp"],
    showHelp: false,
    useAccountSwitcher: false,
    useMcp: false,
    useTilth: false,
  });
});

test("preserves arguments after the Pi delimiter", () => {
  assert.deepEqual(parseLauncherArgs(["--", "tilth"]), {
    passthrough: ["--", "tilth"],
    showHelp: false,
    useAccountSwitcher: false,
    useMcp: false,
    useTilth: false,
  });
});
