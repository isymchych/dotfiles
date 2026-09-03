import { constants } from "node:fs";
import { access } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

import type { AccountProfile } from "./account-profiles.ts";

const excludedToolNames = ["write", "grep", "find", "ls"];
const defaultExtensionNames = [
  "apply-patch",
  "read-tool",
  "compact-tool-output",
  "context",
  "fuzzy-at-file-autocomplete",
  "model-slots",
  "draft-stash",
  "openai-codex",
  "personal-context",
  "preview",
  "response-status",
  "waybar-agent-status",
  "shell-tool",
  "handoff-summary",
  "write-file",
  "snip",
];

async function isExecutable(filePath: string): Promise<boolean> {
  try {
    await access(filePath, constants.X_OK);
    return true;
  } catch {
    return false;
  }
}

async function buildPiArgs(accelOs: string): Promise<string[]> {
  const configDir = path.join(accelOs, "ai", "pi");
  const args = ["--no-extensions", "--append-system-prompt", path.join(accelOs, "ai", "SYSTEM.md")];

  for (const name of defaultExtensionNames) {
    if (name === "snip") {
      const homeDirectory = process.env["HOME"];
      if (
        homeDirectory === undefined ||
        !(await isExecutable(path.join(homeDirectory, ".local", "bin", "snip")))
      ) {
        continue;
      }
    }
    args.push("--extension", path.join(configDir, "extensions", name, "index.ts"));
  }

  args.push("--extension", path.join(accelOs, "node_modules", "pi-mcp-adapter"));
  args.push("--exclude-tools", excludedToolNames.join(","));
  return args;
}

export async function launchPi(
  accelOs: string,
  profile: AccountProfile,
  passthrough: readonly string[],
): Promise<void> {
  const configDir = path.join(accelOs, "ai", "pi");
  process.chdir(process.env["AI_CWD"] ?? process.cwd());
  process.env["PI_CODING_AGENT_DIR"] = profile.directory;
  process.env["PI_CODING_AGENT_SESSION_DIR"] = path.join(configDir, "sessions");

  const args = await buildPiArgs(accelOs);
  const { main } = await import("@earendil-works/pi-coding-agent");
  await main([...args, ...passthrough]);
}
