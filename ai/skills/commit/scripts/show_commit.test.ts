import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { parseRevision, type CommitInspection } from "./show_commit.ts";

const script = new URL("./show_commit.ts", import.meta.url);

function git(cwd: string, ...args: string[]): string {
  return execFileSync("git", args, { cwd, encoding: "utf8" }).trim();
}

test("parseRevision defaults to HEAD and accepts one revision", () => {
  assert.equal(parseRevision([]), "HEAD");
  assert.equal(parseRevision(["HEAD~1"]), "HEAD~1");
  assert.throws(() => parseRevision(["HEAD", "main"]), /at most one revision/);
});

test("show_commit resolves a revision and returns its message and diff", () => {
  const cwd = mkdtempSync(join(tmpdir(), "show-commit-"));

  try {
    git(cwd, "init", "--quiet");
    git(cwd, "config", "user.name", "Commit Test");
    git(cwd, "config", "user.email", "commit-test@example.com");

    writeFileSync(join(cwd, "first.txt"), "first\n");
    git(cwd, "add", "first.txt");
    git(cwd, "commit", "--quiet", "-m", "feat: add first", "-m", "Create the first file.");
    const firstSha = git(cwd, "rev-parse", "HEAD");

    writeFileSync(join(cwd, "second.txt"), "second\n");
    git(cwd, "add", "second.txt");
    git(cwd, "commit", "--quiet", "-m", "feat: add second");

    const output = execFileSync(process.execPath, [script.pathname, "HEAD~1"], {
      cwd,
      encoding: "utf8",
    });
    const inspection = JSON.parse(output) as CommitInspection;

    assert.equal(inspection.sha, firstSha);
    assert.equal(inspection.message, "feat: add first\n\nCreate the first file.");
    assert.match(inspection.diff, /diff --git a\/first\.txt b\/first\.txt/);
    assert.match(inspection.diff, /\+first/);
    assert.doesNotMatch(inspection.diff, /second\.txt/);
  } finally {
    rmSync(cwd, { recursive: true, force: true });
  }
});

test("show_commit rejects a merge commit without an inspectable diff", () => {
  const cwd = mkdtempSync(join(tmpdir(), "show-commit-merge-"));

  try {
    git(cwd, "init", "--quiet");
    git(cwd, "config", "user.name", "Commit Test");
    git(cwd, "config", "user.email", "commit-test@example.com");

    writeFileSync(join(cwd, "base.txt"), "base\n");
    git(cwd, "add", "base.txt");
    git(cwd, "commit", "--quiet", "-m", "feat: add base");
    const mainBranch = git(cwd, "branch", "--show-current");

    git(cwd, "switch", "--quiet", "-c", "feature");
    writeFileSync(join(cwd, "feature.txt"), "feature\n");
    git(cwd, "add", "feature.txt");
    git(cwd, "commit", "--quiet", "-m", "feat: add feature");

    git(cwd, "switch", "--quiet", mainBranch);
    writeFileSync(join(cwd, "main.txt"), "main\n");
    git(cwd, "add", "main.txt");
    git(cwd, "commit", "--quiet", "-m", "feat: add main");
    git(cwd, "merge", "--quiet", "--no-ff", "feature", "-m", "merge feature");

    const result = spawnSync(process.execPath, [script.pathname], {
      cwd,
      encoding: "utf8",
    });

    assert.equal(result.status, 66);
    assert.match(result.stderr, /^ERR_GIT: cannot inspect commit [0-9a-f]+: commit has no diff\n$/);
    assert.equal(result.stdout, "");
  } finally {
    rmSync(cwd, { recursive: true, force: true });
  }
});
