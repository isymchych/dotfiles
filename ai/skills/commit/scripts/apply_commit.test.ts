import assert from "node:assert/strict";
import { execFileSync, spawnSync, type SpawnSyncReturns } from "node:child_process";
import {
  chmodSync as chmod,
  mkdtempSync as makeTempDir,
  rmSync as removeDir,
  writeFileSync as writeFile,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

const applyScript = new URL("./apply_commit.ts", import.meta.url);

function git(cwd: string, ...args: string[]): string {
  return execFileSync("git", args, { cwd, encoding: "utf8" }).trim();
}

function gitRaw(cwd: string, ...args: string[]): string {
  return execFileSync("git", args, { cwd, encoding: "utf8" });
}

function run(script: URL, cwd: string, args: string[], input?: string): SpawnSyncReturns<string> {
  return spawnSync(process.execPath, [script.pathname, ...args], {
    cwd,
    encoding: "utf8",
    input,
  });
}

function createRepository(): string {
  const cwd = makeTempDir(join(tmpdir(), "commit-helper-"));
  git(cwd, "init", "--quiet");
  git(cwd, "config", "user.name", "Commit Test");
  git(cwd, "config", "user.email", "commit-test@example.com");
  return cwd;
}

function commitFile(cwd: string, filename: string, contents: string, message: string): string {
  writeFile(join(cwd, filename), contents);
  git(cwd, "add", filename);
  git(cwd, "commit", "--quiet", "-m", message);
  return git(cwd, "rev-parse", "HEAD");
}

function commitBody(cwd: string): string {
  const content = gitRaw(cwd, "cat-file", "commit", "HEAD");
  return content.slice(content.indexOf("\n\n") + 2);
}

test("apply_commit creates a commit without rewriting its message", () => {
  const cwd = createRepository();

  try {
    writeFile(join(cwd, "new.txt"), "new\n");
    git(cwd, "add", "new.txt");
    const message = "feat: preserve message\n\n  indented detail\nhttps://example.test/a?x=1\n";

    const result = run(applyScript, cwd, ["create"], message);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /^OK [0-9a-f]{40}\n$/);
    assert.equal(commitBody(cwd), message);
  } finally {
    removeDir(cwd, { recursive: true, force: true });
  }
});

test("apply_commit preserves staged changes when amending only a message", () => {
  const cwd = createRepository();

  try {
    const expectedHead = commitFile(cwd, "committed.txt", "committed\n", "feat: old message");
    writeFile(join(cwd, "staged.txt"), "staged\n");
    git(cwd, "add", "staged.txt");

    const result = run(
      applyScript,
      cwd,
      ["amend", "--expected-head", expectedHead],
      "feat: new message\n",
    );
    assert.equal(result.status, 0, result.stderr);
    assert.equal(git(cwd, "diff", "--cached", "--name-only"), "staged.txt");
    assert.equal(git(cwd, "show", "--format=", "--name-only", "HEAD"), "committed.txt");
    assert.equal(commitBody(cwd), "feat: new message\n");
  } finally {
    removeDir(cwd, { recursive: true, force: true });
  }
});

test("apply_commit rejects stale or published amends unless explicitly allowed", () => {
  const cwd = createRepository();
  const remote = makeTempDir(join(tmpdir(), "commit-helper-remote-"));

  try {
    const expectedHead = commitFile(cwd, "first.txt", "first\n", "feat: first");
    commitFile(cwd, "second.txt", "second\n", "feat: second");
    const stale = run(
      applyScript,
      cwd,
      ["amend", "--expected-head", expectedHead],
      "feat: stale\n",
    );
    assert.equal(stale.status, 67);
    assert.match(stale.stderr, /^ERR_HEAD_CHANGED\n/);

    git(remote, "init", "--bare", "--quiet");
    git(cwd, "remote", "add", "origin", remote);
    git(cwd, "push", "--quiet", "-u", "origin", "HEAD:main");
    const currentHead = git(cwd, "rev-parse", "HEAD");

    const published = run(
      applyScript,
      cwd,
      ["amend", "--expected-head", currentHead],
      "feat: published\n",
    );
    assert.equal(published.status, 68);
    assert.match(published.stderr, /^ERR_PUBLISHED_COMMIT\n/);

    const allowed = run(
      applyScript,
      cwd,
      ["amend", "--expected-head", currentHead, "--allow-published"],
      "feat: published\n",
    );
    assert.equal(allowed.status, 0, allowed.stderr);
  } finally {
    removeDir(cwd, { recursive: true, force: true });
    removeDir(remote, { recursive: true, force: true });
  }
});

test("apply_commit honors hooks unless --no-verify is requested", () => {
  const cwd = createRepository();

  try {
    writeFile(join(cwd, "hooked.txt"), "hooked\n");
    git(cwd, "add", "hooked.txt");
    const hook = join(cwd, ".git", "hooks", "pre-commit");
    writeFile(hook, "#!/bin/sh\necho pre-commit >&2\nexit 1\n");
    chmod(hook, 0o755);

    const blocked = run(applyScript, cwd, ["create"], "feat: blocked\n");
    assert.equal(blocked.status, 3);
    assert.match(blocked.stderr, /^ERR_GIT_HOOK_PRE_COMMIT\n/);

    const allowed = run(applyScript, cwd, ["create", "--no-verify"], "feat: allowed\n");
    assert.equal(allowed.status, 0, allowed.stderr);
  } finally {
    removeDir(cwd, { recursive: true, force: true });
  }
});
