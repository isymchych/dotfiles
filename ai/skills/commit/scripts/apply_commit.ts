import { getErrorMessage } from "@accel-os/shared/guards";

import { runGit, type GitCommandResult } from "../../lib/git_command.ts";
import {
  classifyGitFailure,
  formatGitError,
  printStructuredGitError,
} from "../../lib/git_error.ts";

const BODY_LINE_MAX = 99;

type CommitMode = "create" | "amend";

type ApplyOptions = {
  mode: CommitMode;
  noVerify: boolean;
  allowSubjectOnly: boolean;
  verbatim: boolean;
  expectedHead: string | null;
  allowPublished: boolean;
};

class UsageError extends Error {}
class MessageError extends Error {}

function parseOptions(args: string[]): ApplyOptions {
  const [mode, ...rest] = args;
  if (mode !== "create" && mode !== "amend") throw new UsageError("expected `create` or `amend`");

  const options: ApplyOptions = {
    mode,
    noVerify: false,
    allowSubjectOnly: false,
    verbatim: false,
    expectedHead: null,
    allowPublished: false,
  };

  for (let index = 0; index < rest.length; index += 1) {
    const arg = rest[index];
    if (arg === "--no-verify") {
      options.noVerify = true;
      continue;
    }
    if (arg === "--allow-subject-only") {
      options.allowSubjectOnly = true;
      continue;
    }
    if (arg === "--verbatim") {
      options.verbatim = true;
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
  if (!message.trim()) throw new MessageError("empty commit message");
  return message;
}

function normalizeMessage(message: string): string {
  const lines = message.trim().split(/\r?\n/);
  const subject = lines[0]?.trim() ?? "";
  if (!subject) throw new MessageError("empty commit subject");

  const bodySource = lines[1]?.trim() === "" ? lines.slice(2) : lines.slice(1);
  const bodyLines: string[] = [];
  for (const line of bodySource) bodyLines.push(...wrapLine(line.trimEnd()));
  while (bodyLines.length > 0 && bodyLines[bodyLines.length - 1] === "") bodyLines.pop();

  if (bodyLines.length === 0) return `${subject}\n`;
  return `${[subject, "", ...bodyLines].join("\n")}\n`;
}

function wrapLine(line: string): string[] {
  if (line === "") return [""];
  if (line.startsWith("- ")) {
    const marker = "- ";
    const wrapped = wrapText(line.slice(marker.length).trim(), BODY_LINE_MAX - marker.length);
    if (wrapped.length === 0) return ["-"];
    return [`${marker}${wrapped[0]}`, ...wrapped.slice(1).map((part) => `  ${part}`)];
  }

  const leadingSpaces = line.length - line.trimStart().length;
  const indent = " ".repeat(leadingSpaces);
  const wrapped = wrapText(line.trim(), BODY_LINE_MAX - leadingSpaces);
  if (wrapped.length === 0) return [indent];
  return wrapped.map((part) => `${indent}${part}`);
}

function wrapText(text: string, width: number): string[] {
  if (text === "") return [];
  if (width < 1) return [text];

  const words = text.split(/\s+/).filter(Boolean);
  const lines: string[] = [];
  let current = "";

  for (const word of words) {
    if (current === "") {
      if (word.length <= width) {
        current = word;
      } else {
        lines.push(...splitLongToken(word, width));
      }
      continue;
    }
    if (current.length + 1 + word.length <= width) {
      current = `${current} ${word}`;
      continue;
    }

    lines.push(current);
    if (word.length <= width) {
      current = word;
    } else {
      const pieces = splitLongToken(word, width);
      lines.push(...pieces.slice(0, -1));
      current = pieces.at(-1) ?? "";
    }
  }

  if (current !== "") lines.push(current);
  return lines;
}

function splitLongToken(token: string, width: number): string[] {
  const chunks: string[] = [];
  for (let index = 0; index < token.length; index += width) {
    chunks.push(token.slice(index, index + width));
  }
  return chunks;
}

function validateMessage(message: string, options: ApplyOptions): void {
  const [subject = "", ...bodyLines] = message.split(/\r?\n/);
  if (!subject.trim()) throw new MessageError("empty commit subject");
  if (!options.allowSubjectOnly && !bodyLines.some((line) => line.trim())) {
    throw new MessageError(
      "subject-only commit message requires explicit --allow-subject-only override",
    );
  }
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
    const rawMessage = await readMessage();
    const message = options.verbatim ? rawMessage : normalizeMessage(rawMessage);
    validateMessage(message, options);
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
        : error instanceof MessageError
          ? "ERR_MESSAGE_INVALID"
          : "ERR_INTERNAL";
    printStructuredGitError(formatGitError(code, message, ""));
    process.exit(code === "ERR_USAGE" || code === "ERR_MESSAGE_INVALID" ? 2 : 4);
  }
}
