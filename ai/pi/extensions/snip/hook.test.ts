import assert from "node:assert/strict";
import test from "node:test";

import { parseSnipHookOutput, runSnipHook, type SnipHookPayload } from "./hook.ts";
import { createSnipHookSession } from "./index.ts";

test("parseSnipHookOutput returns the rewritten bash command", () => {
  assert.equal(
    parseSnipHookOutput(
      JSON.stringify({
        hookSpecificOutput: {
          updatedInput: {
            command: '"/home/user/.local/bin/snip" run -- git status',
            timeout: 30,
          },
          permissionDecision: "allow",
        },
      }),
    ),
    '"/home/user/.local/bin/snip" run -- git status',
  );
});

test("parseSnipHookOutput returns undefined for a pass-through response", () => {
  assert.equal(parseSnipHookOutput("{}"), undefined);
});

test("parseSnipHookOutput rejects malformed hook output", () => {
  assert.throws(() => parseSnipHookOutput("{invalid"), /snip hook output: invalid JSON syntax/u);
});

test("parseSnipHookOutput rejects a non-string command", () => {
  assert.throws(
    () =>
      parseSnipHookOutput(
        JSON.stringify({
          hookSpecificOutput: {
            updatedInput: {
              command: 1,
            },
          },
        }),
      ),
    /snip hook output: invalid JSON/u,
  );
});

test("runSnipHook invokes the pinned binary without a shell", async () => {
  const payload: SnipHookPayload = {
    tool_name: "bash",
    tool_input: {
      command: "git status",
      cwd: "/work",
    },
  };
  let binaryPath = "";
  let receivedPayload: SnipHookPayload | undefined;

  const command = await runSnipHook(payload, {
    binaryPath: "/home/user/.local/bin/snip",
    async execute(path, input) {
      binaryPath = path;
      receivedPayload = input;
      return JSON.stringify({
        hookSpecificOutput: {
          updatedInput: {
            command: '"/home/user/.local/bin/snip" run -- git status',
          },
        },
      });
    },
  });

  assert.equal(binaryPath, "/home/user/.local/bin/snip");
  assert.deepEqual(receivedPayload, payload);
  assert.equal(command, '"/home/user/.local/bin/snip" run -- git status');
});

test("runSnipHook propagates hook failures for fail-open handling", async () => {
  await assert.rejects(
    runSnipHook(
      {
        tool_name: "bash",
        tool_input: { command: "git status" },
      },
      {
        async execute() {
          throw new Error("snip unavailable");
        },
      },
    ),
    /snip unavailable/u,
  );
});

test("createSnipHookSession disables future hook calls after a failure", async () => {
  let calls = 0;
  const session = createSnipHookSession(async () => {
    calls += 1;
    throw new Error("snip unavailable");
  });

  const first = await session.rewrite({ command: "git status" });
  const second = await session.rewrite({ command: "git diff" });

  assert.equal(calls, 1);
  assert.match(String(first.error), /snip unavailable/u);
  assert.equal(second.error, undefined);
});

test("createSnipHookSession keeps the hook enabled when its turn is aborted", async () => {
  let calls = 0;
  const controller = new AbortController();
  const session = createSnipHookSession(async () => {
    calls += 1;
    throw new Error("aborted");
  });

  controller.abort();
  await session.rewrite({ command: "git status" }, controller.signal);
  await session.rewrite({ command: "git diff" });

  assert.equal(calls, 2);
});
