import assert from "node:assert/strict";
import test from "node:test";

import { createTilthShellHint } from "./hints.ts";

const allTilthTools = new Set([
  "tilth_search",
  "tilth_read",
  "tilth_list",
  "tilth_grok",
  "tilth_diff",
]);

test("createTilthShellHint maps search and file-reading commands to Tilth tools", () => {
  assert.equal(
    createTilthShellHint("rg handleAuth src && head -80 src/auth.ts", allTilthTools),
    "Hint: for code exploration, prefer Tilth tools here: use tilth_search instead of rg/grep/git grep for code search; for another checkout, set scope to its absolute path; use tilth_read instead of cat/head/tail for file contents.",
  );
});

test("createTilthShellHint handles piped find-style commands", () => {
  assert.equal(
    createTilthShellHint("fd auth | xargs grep token", allTilthTools),
    "Hint: for code exploration, prefer Tilth tools here: use tilth_search instead of rg/grep/git grep for code search; for another checkout, set scope to its absolute path; use tilth_list instead of find/fd/ls/tree for file discovery.",
  );
});

test("createTilthShellHint maps directory listing commands to tilth_list", () => {
  assert.equal(
    createTilthShellHint("ls src && tree packages", allTilthTools),
    "Hint: for code exploration, prefer Tilth tools here: use tilth_list instead of find/fd/ls/tree for file discovery.",
  );
});

test("createTilthShellHint maps git discovery commands to Tilth tools with an external checkout path", () => {
  assert.equal(
    createTilthShellHint("git grep handleAuth && git ls-files src", allTilthTools),
    "Hint: for code exploration, prefer Tilth tools here: use tilth_search instead of rg/grep/git grep for code search; for another checkout, set scope to its absolute path; use tilth_list instead of git ls-files for file discovery; for another checkout, set scope to its absolute path.",
  );
});

test("createTilthShellHint routes structural diff review to tilth_diff", () => {
  assert.equal(
    createTilthShellHint("git --no-pager diff --cached", allTilthTools),
    "Hint: for code exploration, prefer Tilth tools here: use tilth_diff for structural change review; use git diff --patch only for exact patch text.",
  );
});

test("createTilthShellHint skips unavailable Tilth tools", () => {
  assert.equal(createTilthShellHint("cat README.md", new Set(["tilth_search"])), undefined);
});

test("createTilthShellHint ignores unrelated shell commands", () => {
  assert.equal(createTilthShellHint("git status", allTilthTools), undefined);
});
