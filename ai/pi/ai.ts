#!/usr/bin/env node
import { readFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { createInterface } from "node:readline/promises";

import { parseJsonWithSchema } from "@accel-os/shared/json";
import { Type } from "typebox";

import {
  parseOpenAICodexCredential,
  resolveOpenAICodexRuntimeAccountProfile,
} from "./extensions/openai-codex/auth.ts";
import { renderUsageSummary } from "./extensions/openai-codex/status.ts";
import {
  type OpenAICodexUsageCredential,
  fetchUsageSnapshotForCredential,
} from "./extensions/openai-codex/usage.ts";
import {
  type AccountProfile,
  createNewAccountProfile,
  finalizeNewAccountProfile,
  findNewAccountProfile,
  listAccountProfiles,
  readActiveProfileName,
  writeActiveProfileName,
} from "./runtime/account-profiles.ts";

const usage = `ai [account] [mcp] [-- <pi args...>]

Examples:
  ai
  ai account
  ai mcp
  ai -- --help

Notes:
  - By default, ai appends ai/SYSTEM.md.
  - \`mcp\` enables the MCP proxy tool for this run.
  - \`account\` selects an isolated OpenAI Codex credential profile and then opens Pi.
  - Each profile has its own auth.json, so changing accounts does not affect existing chats.
  - Use \`ai -- --help\` to show Pi CLI docs.`;

const accelOs = process.env["ACCEL_OS"];
if (accelOs === undefined || accelOs.length === 0) {
  process.stderr.write("ai: ACCEL_OS is not set\n");
  process.exit(1);
}

const configDir = path.join(accelOs, "ai", "pi");
const appendSystemPromptPath = path.join(accelOs, "ai", "SYSTEM.md");
const accountUsageTimeoutMs = 20_000;
const authFileSchema = Type.Record(Type.String(), Type.Unknown());

const defaultToolNames = [
  "bash",
  "apply_patch",
  "write_file",
  "tilth_read",
  "tilth_search",
  "tilth_files",
  "tilth_deps",
  "tilth_grok",
  "read",
  // "grep",
  // "find",
  // "ls",
];

type AccountInfo = {
  id: string;
  email: string;
  plan: string;
  profile: AccountProfile;
  isCurrent: boolean;
  accessToken?: string;
};

type AccountAction =
  | { kind: "noop"; labelLines: string[]; account: AccountInfo }
  | { kind: "new"; labelLines: string[] }
  | { kind: "switch"; labelLines: string[]; account: AccountInfo };

const writeStdout = (message: string): void => {
  process.stdout.write(`${message}\n`);
};

const writeStderr = (message: string): void => {
  process.stderr.write(`${message}\n`);
};

const hasExplicitToolSelection = (args: readonly string[]): boolean => {
  return args.some(
    (arg) => arg === "--tools" || arg.startsWith("--tools=") || arg === "--no-tools",
  );
};

const buildAppendArgs = (passthrough: readonly string[], useMcp: boolean): string[] => {
  const appendArgs = ["--append-system-prompt", appendSystemPromptPath];
  if (!hasExplicitToolSelection(passthrough)) {
    const toolNames = useMcp ? [...defaultToolNames, "mcp"] : defaultToolNames;
    appendArgs.push("--tools", toolNames.join(","));
  }
  return appendArgs;
};

const parseAccountInfo = (
  raw: string,
  profile: AccountProfile,
  isCurrent: boolean,
): AccountInfo => {
  const parsed = parseJsonWithSchema(raw, authFileSchema, profile.authPath);

  const credential = parseOpenAICodexCredential(parsed["openai-codex"]);
  if (credential === null) {
    throw new Error(`missing openai-codex OAuth credential in ${profile.authPath}`);
  }

  const account = resolveOpenAICodexRuntimeAccountProfile(credential, credential.access);
  const id = account.accountId;
  if (id === undefined || id.length === 0) {
    throw new Error(`missing openai-codex.accountId in ${profile.authPath}`);
  }

  const info: AccountInfo = {
    id,
    email: account.email ?? "unknown",
    plan: account.plan ?? "unknown",
    profile,
    isCurrent,
  };
  if (credential.access !== undefined && credential.access.length > 0) {
    info.accessToken = credential.access;
  }
  return info;
};

const loadAccount = async (profile: AccountProfile, isCurrent: boolean): Promise<AccountInfo> => {
  return parseAccountInfo(await readFile(profile.authPath, "utf8"), profile, isCurrent);
};

const resolveUsageIdentityValue = (value: string): string | undefined => {
  return value === "unknown" ? undefined : value;
};

const fetchAccountUsageSummary = async (account: AccountInfo): Promise<string> => {
  if (account.accessToken === undefined) {
    return "usage unavailable";
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => {
    controller.abort();
  }, accountUsageTimeoutMs);

  try {
    const credential: OpenAICodexUsageCredential = {
      accessToken: account.accessToken,
      accountId: account.id,
    };
    const email = resolveUsageIdentityValue(account.email);
    if (email !== undefined) {
      credential.email = email;
    }
    const plan = resolveUsageIdentityValue(account.plan);
    if (plan !== undefined) {
      credential.plan = plan;
    }

    const snapshot = await fetchUsageSnapshotForCredential(credential, {
      signal: controller.signal,
    });
    return renderUsageSummary(snapshot);
  } catch {
    return "usage unavailable";
  } finally {
    clearTimeout(timeout);
  }
};

const fetchAccountUsageSummaries = async (
  accounts: readonly AccountInfo[],
): Promise<Map<string, string>> => {
  const entries = await Promise.all(
    accounts.map(async (account): Promise<readonly [string, string]> => [
      account.id,
      await fetchAccountUsageSummary(account),
    ]),
  );
  return new Map(entries);
};

const formatAccountActionLines = (account: AccountInfo, usageSummary: string): string[] => {
  const currentMarker = account.isCurrent ? "*" : " ";
  return [
    `${currentMarker} ${account.email} (${account.plan})`,
    `  id: ${account.id}`,
    `  ${usageSummary}`,
  ];
};

const renderAction = (action: AccountAction, index: number): void => {
  const prefix = `  ${index + 1}) `;
  const continuationPrefix = " ".repeat(prefix.length);
  const firstLine = action.labelLines[0];
  if (firstLine === undefined) {
    return;
  }
  writeStdout(`${prefix}${firstLine}`);
  for (const line of action.labelLines.slice(1)) {
    writeStdout(`${continuationPrefix}${line}`);
  }
};

const promptChoice = async (count: number): Promise<number> => {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  try {
    const input = await rl.question("Choice: ");
    if (input.length === 0) {
      throw new Error("no selection provided");
    }
    const parsed = Number.parseInt(input, 10);
    if (!Number.isFinite(parsed) || parsed < 1 || parsed > count) {
      throw new Error("invalid selection");
    }
    return parsed - 1;
  } finally {
    rl.close();
  }
};

async function prepareAccountProfiles(): Promise<{
  profiles: AccountProfile[];
  activeProfileName?: string;
}> {
  let activeProfileName = await readActiveProfileName(configDir);
  const pending = await findNewAccountProfile(configDir);
  if (pending !== undefined) {
    try {
      const pendingAccount = await loadAccount(pending, false);
      const finalized = await finalizeNewAccountProfile(configDir, pendingAccount.id);
      if (finalized !== undefined && activeProfileName === pending.name) {
        activeProfileName = finalized.name;
        await writeActiveProfileName(configDir, activeProfileName);
      }
    } catch (error: unknown) {
      if (!(error instanceof Error && "code" in error && error.code === "ENOENT")) {
        throw error;
      }
    }
  }

  const profiles = await listAccountProfiles(configDir);
  if (
    activeProfileName !== undefined &&
    !profiles.some((profile) => profile.name === activeProfileName)
  ) {
    activeProfileName = undefined;
  }
  if (activeProfileName === undefined && profiles.length === 1) {
    const profile = profiles[0];
    if (profile !== undefined) {
      activeProfileName = profile.name;
      await writeActiveProfileName(configDir, activeProfileName);
    }
  }

  return activeProfileName === undefined ? { profiles } : { profiles, activeProfileName };
}

async function getActiveAccountProfile(): Promise<AccountProfile> {
  const { profiles, activeProfileName } = await prepareAccountProfiles();
  const active = profiles.find((profile) => profile.name === activeProfileName);
  if (active !== undefined) {
    return active;
  }
  if (profiles.length === 0) {
    const profile = await createNewAccountProfile(configDir);
    await writeActiveProfileName(configDir, profile.name);
    return profile;
  }
  throw new Error("multiple account profiles exist; run `ai account` to select one");
}

async function runAccountSwitcher(): Promise<AccountProfile> {
  if (!process.stdin.isTTY) {
    throw new Error("account switcher requires a TTY");
  }

  const { profiles, activeProfileName } = await prepareAccountProfiles();
  const accounts = await Promise.all(
    profiles.map(async (profile) => await loadAccount(profile, profile.name === activeProfileName)),
  );

  writeStdout("Loading usage...");
  const usageByAccountId = await fetchAccountUsageSummaries(accounts);

  writeStdout("Select account:");
  writeStdout("");
  const actions: AccountAction[] = accounts.map((account) => {
    const usageSummary = usageByAccountId.get(account.id) ?? "usage unavailable";
    const labelLines = formatAccountActionLines(account, usageSummary);
    return account.isCurrent
      ? { kind: "noop", labelLines, account }
      : { kind: "switch", labelLines, account };
  });
  actions.push({ kind: "new", labelLines: ["+ new account"] });

  actions.forEach((action, index) => {
    renderAction(action, index);
    if (index < actions.length - 1) {
      writeStdout("");
    }
  });

  const selected = actions[await promptChoice(actions.length)];
  if (selected === undefined) {
    throw new Error("invalid selection");
  }
  if (selected.kind === "new") {
    const profile = await createNewAccountProfile(configDir);
    await writeActiveProfileName(configDir, profile.name);
    writeStdout("New account profile selected. Run /login and choose OpenAI Codex.");
    return profile;
  }

  await writeActiveProfileName(configDir, selected.account.profile.name);
  if (selected.kind === "noop") {
    writeStdout("Account already active.");
  } else {
    writeStdout(`Selected ${selected.account.id}.`);
  }
  return selected.account.profile;
}

const passthrough: string[] = [];
let parseModifiers = true;
let showHelp = false;
let useAccountSwitcher = false;
let useMcp = false;

for (const arg of process.argv.slice(2)) {
  if (!parseModifiers) {
    passthrough.push(arg);
    continue;
  }
  if (arg === "--") {
    parseModifiers = false;
    passthrough.push(arg);
    continue;
  }
  if (arg === "help") {
    showHelp = true;
    continue;
  }
  if (arg === "account") {
    useAccountSwitcher = true;
    continue;
  }
  if (arg === "mcp") {
    useMcp = true;
    continue;
  }
  passthrough.push(arg);
}

if (showHelp) {
  writeStdout(usage);
  process.exit(0);
}

let profile: AccountProfile;
try {
  profile = useAccountSwitcher ? await runAccountSwitcher() : await getActiveAccountProfile();
} catch (error: unknown) {
  const message = error instanceof Error ? error.message : String(error);
  writeStderr(`ai: ${message}`);
  process.exit(1);
}

const cwd = process.env["AI_CWD"] ?? process.cwd();
process.chdir(cwd);
process.env["PI_CODING_AGENT_DIR"] = profile.directory;
process.env["PI_CODING_AGENT_SESSION_DIR"] = path.join(configDir, "sessions");

const appendArgs = buildAppendArgs(passthrough, useMcp);
const { main } = await import("@earendil-works/pi-coding-agent");
await main([...appendArgs, ...passthrough]);
