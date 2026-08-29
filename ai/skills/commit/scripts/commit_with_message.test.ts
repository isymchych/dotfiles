import assert from "node:assert/strict";
import test from "node:test";

import {
  buildAmendArgs,
  buildCommitArgs,
  normalizeMessage,
  parseCommitOptions,
} from "./commit_with_message.ts";

const message = "feat: add thing\n\nAdd thing.\n";

test("buildCommitArgs uses normal git commit by default", () => {
  assert.deepEqual(buildCommitArgs(message, parseCommitOptions([])), [
    "commit",
    "-m",
    "feat: add thing",
    "-m",
    "Add thing.",
  ]);
});

test("buildCommitArgs includes --no-verify when requested", () => {
  assert.deepEqual(buildCommitArgs(message, parseCommitOptions(["--no-verify"])), [
    "commit",
    "--no-verify",
    "-m",
    "feat: add thing",
    "-m",
    "Add thing.",
  ]);
});

test("buildAmendArgs preserves staged changes while replacing the last message", () => {
  assert.deepEqual(buildAmendArgs(message, parseCommitOptions([])), [
    "commit",
    "--amend",
    "--only",
    "-m",
    "feat: add thing",
    "-m",
    "Add thing.",
  ]);
});

test("parseCommitOptions rejects unknown arguments", () => {
  assert.throws(() => parseCommitOptions(["--oops"]), /unknown argument: --oops/);
});

test("normalizeMessage trims surrounding whitespace", () => {
  assert.equal(
    normalizeMessage("\n  feat: add thing  \n\nAdd thing.  \n\n"),
    "feat: add thing\n\nAdd thing.\n",
  );
});

test("normalizeMessage accepts a whitespace-only body separator", () => {
  assert.equal(
    normalizeMessage("feat: add thing\n   \nAdd thing."),
    "feat: add thing\n\nAdd thing.\n",
  );
});

test("normalizeMessage preserves body indentation", () => {
  assert.equal(
    normalizeMessage("feat: add thing\n\n  indented detail"),
    "feat: add thing\n\n  indented detail\n",
  );
});

test("normalizeMessage rejects whitespace-only input", () => {
  assert.throws(() => normalizeMessage(" \n\t "), /empty commit subject/);
});
