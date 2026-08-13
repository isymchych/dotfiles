import { getErrorMessage } from "@accel-os/shared/guards";

import { runGit, type GitCommandResult } from "../../lib/git_command.ts";
import {
  classifyGitFailure,
  formatGitError,
  printStructuredGitError,
} from "../../lib/git_error.ts";
import { buildAmendArgs, normalizeMessage, parseCommitOptions } from "./commit_with_message.ts";

async function readInput(): Promise<string> {
  process.stdin.setEncoding("utf8");
  const chunks: string[] = [];
  for await (const chunk of process.stdin) chunks.push(String(chunk));
  return chunks.join("");
}

async function amendCommitMessage(
  message: string,
  options: { noVerify: boolean },
): Promise<GitCommandResult> {
  return await runGit(buildAmendArgs(message, options));
}

async function readHeadSha(): Promise<string> {
  const result = await runGit(["rev-parse", "HEAD"]);
  if (result.code !== 0) throw new Error("failed to read commit sha after successful amend");
  const sha = result.stdout.trim();
  if (!sha) throw new Error("git rev-parse returned empty commit sha");
  return sha;
}

if (import.meta.main) {
  try {
    const options = parseCommitOptions(process.argv.slice(2));
    const normalized = normalizeMessage(await readInput());
    const result = await amendCommitMessage(normalized, options);

    if (result.code === 0) {
      console.log(`OK ${await readHeadSha()}`);
      process.exit(0);
    }

    printStructuredGitError(classifyGitFailure(result.stdout, result.stderr));
    process.exit(3);
  } catch (error) {
    const message = getErrorMessage(error);
    const code = message.startsWith("unknown argument:")
      ? "ERR_USAGE"
      : message.startsWith("empty commit")
        ? "ERR_MESSAGE_INVALID"
        : "ERR_INTERNAL";
    printStructuredGitError(formatGitError(code, message, ""));
    process.exit(code === "ERR_USAGE" || code === "ERR_MESSAGE_INVALID" ? 2 : 4);
  }
}
