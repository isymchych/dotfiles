import { getErrorMessage } from "@accel-os/shared/guards";

import { runGit, type GitCommandResult } from "../../lib/git_command.ts";
import {
  classifyGitFailure,
  formatGitError,
  printStructuredGitError,
} from "../../lib/git_error.ts";

type CommitMode = "create" | "amend";

type ApplyOptions = {
  mode: CommitMode;
  noVerify: boolean;
  expectedHead: string | null;
  allowPublished: boolean;
};

class UsageError extends Error {}

function parseOptions(args: string[]): ApplyOptions {
  const [mode, ...rest] = args;
  if (mode !== "create" && mode !== "amend") throw new UsageError("expected `create` or `amend`");

  const options: ApplyOptions = {
    mode,
    noVerify: false,
    expectedHead: null,
    allowPublished: false,
  };

  for (let index = 0; index < rest.length; index += 1) {
    const arg = rest[index];
    if (arg === "--no-verify") {
      options.noVerify = true;
      continue;
    }
    if (arg === "--allow-published" && mode === "amend") {
      options.allowPublished = true;
      continue;
    }
    if (arg === "--expected-head" && mode === "amend") {
      const sha = rest[index + 1];
      if (!sha) throw new UsageError("--expected-head requires a commit SHA");
      options.expectedHead = sha;
      index += 1;
      continue;
    }
    throw new UsageError(`unknown argument: ${arg ?? ""}`);
  }

  if (mode === "amend" && !options.expectedHead) {
    throw new UsageError("amend requires --expected-head <sha>");
  }
  return options;
}

async function readMessage(): Promise<string> {
  process.stdin.setEncoding("utf8");
  const chunks: string[] = [];
  for await (const chunk of process.stdin) chunks.push(String(chunk));
  const message = chunks.join("");
  if (!message.trim()) throw new Error("empty commit message");
  return message;
}

async function requireGit(result: GitCommandResult, context: string): Promise<string> {
  if (result.success) return result.stdout;
  throw new Error(
    `${context}: ${result.stderr || result.stdout || `git exited with status ${result.code}`}`,
  );
}

async function verifyAmendSafety(options: ApplyOptions): Promise<void> {
  const head = (await requireGit(await runGit(["rev-parse", "HEAD"]), "cannot read HEAD")).trim();
  if (head !== options.expectedHead) {
    printStructuredGitError(
      formatGitError("ERR_HEAD_CHANGED", "HEAD changed since amend confirmation", ""),
    );
    process.exit(67);
  }

  const refs = await requireGit(
    await runGit([
      "for-each-ref",
      "--format=%(refname:short)",
      `--contains=${head}`,
      "refs/remotes",
    ]),
    "cannot check HEAD publication",
  );
  if (refs.split(/\r?\n/).some(Boolean) && !options.allowPublished) {
    printStructuredGitError(
      formatGitError(
        "ERR_PUBLISHED_COMMIT",
        "refusing to amend a published commit without --allow-published",
        refs,
      ),
    );
    process.exit(68);
  }
}

function buildArgs(options: ApplyOptions): string[] {
  const args = ["commit"];
  if (options.mode === "amend") args.push("--amend", "--only");
  if (options.noVerify) args.push("--no-verify");
  args.push("--cleanup=verbatim", "-F", "-");
  return args;
}

async function readHeadSha(): Promise<string> {
  return (
    await requireGit(await runGit(["rev-parse", "HEAD"]), "cannot read resulting HEAD")
  ).trim();
}

if (import.meta.main) {
  try {
    const options = parseOptions(process.argv.slice(2));
    const message = await readMessage();
    if (options.mode === "amend") await verifyAmendSafety(options);

    const result = await runGit(buildArgs(options), { stdin: message });
    if (result.success) {
      console.log(`OK ${await readHeadSha()}`);
      process.exit(0);
    }

    printStructuredGitError(classifyGitFailure(result.stdout, result.stderr));
    process.exit(3);
  } catch (error) {
    const message = getErrorMessage(error);
    const code =
      error instanceof UsageError
        ? "ERR_USAGE"
        : message.startsWith("empty commit")
          ? "ERR_MESSAGE_INVALID"
          : "ERR_INTERNAL";
    printStructuredGitError(formatGitError(code, message, ""));
    process.exit(code === "ERR_USAGE" || code === "ERR_MESSAGE_INVALID" ? 2 : 4);
  }
}
