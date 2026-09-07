import { runGit, type GitCommandResult } from "../../lib/git_command.ts";

export type CommitInspection = {
  sha: string;
  message: string;
  diff: string;
};

export function parseRevision(args: string[]): string {
  if (args.length > 1) throw new Error("expected at most one revision");
  return args[0] ?? "HEAD";
}

async function requireGitResult(result: GitCommandResult, context: string): Promise<string> {
  if (result.success) return result.stdout;

  const errorText = result.stderr || result.stdout || `git exited with status ${result.code}`;
  throw new Error(`${context}: ${errorText}`);
}

export async function inspectCommit(revision: string): Promise<CommitInspection> {
  const resolved = await runGit([
    "rev-parse",
    "--verify",
    "--end-of-options",
    `${revision}^{commit}`,
  ]);
  const sha = await requireGitResult(resolved, `cannot resolve commit ${revision}`);

  const message = await requireGitResult(
    await runGit(["show", "--no-patch", "--format=%B", sha, "--"]),
    `cannot read commit message ${sha}`,
  );
  const diff = await requireGitResult(
    await runGit([
      "show",
      "--format=",
      "--patch",
      "--root",
      "--no-color",
      "--no-ext-diff",
      sha,
      "--",
    ]),
    `cannot read commit diff ${sha}`,
  );
  if (!diff) throw new Error(`cannot inspect commit ${sha}: commit has no diff`);

  return { sha, message, diff };
}

if (import.meta.main) {
  try {
    const revision = parseRevision(process.argv.slice(2));
    console.log(JSON.stringify(await inspectCommit(revision)));
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const code = message === "expected at most one revision" ? "ERR_USAGE" : "ERR_GIT";
    console.error(`${code}: ${message}`);
    process.exit(code === "ERR_USAGE" ? 64 : 66);
  }
}
