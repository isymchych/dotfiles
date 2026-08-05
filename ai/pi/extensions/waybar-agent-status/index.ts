/**
 * Publishes each Pi process' agent-loop state for the Waybar Pi agents module.
 *
 * The extension writes one small per-process state file under XDG_RUNTIME_DIR so
 * external status bars can count agents that are actively running a turn without
 * scraping terminal UI or guessing from process names.
 */
import { mkdir, rm, writeFile, rename } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import process from "node:process";

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type AgentState = "idle" | "working";

const STATE_ROOT_NAME = "accel-os/pi-agents";

function getRuntimeRoot(): string {
  const runtimeDir = process.env["XDG_RUNTIME_DIR"];
  if (runtimeDir !== undefined && runtimeDir.length > 0) {
    return runtimeDir;
  }

  const uid = typeof process.getuid === "function" ? process.getuid() : "unknown";
  return path.join(tmpdir(), `accel-os-${uid}`);
}

function getStateDir(): string {
  return path.join(getRuntimeRoot(), STATE_ROOT_NAME);
}

function getStateFile(): string {
  return path.join(getStateDir(), `${process.pid}.state`);
}

async function writeState(state: AgentState, ctx: ExtensionContext): Promise<void> {
  const stateDir = getStateDir();
  await mkdir(stateDir, { recursive: true });

  const stateFile = getStateFile();
  const tmpFile = `${stateFile}.${process.hrtime.bigint()}.tmp`;
  const content = `${state}\n${Date.now()}\n${ctx.cwd}\n`;
  await writeFile(tmpFile, content, "utf8");
  await rename(tmpFile, stateFile);
}

async function removeState(): Promise<void> {
  await rm(getStateFile(), { force: true });
}

export default function waybarAgentStatusExtension(pi: ExtensionAPI): void {
  pi.on("session_start", async (_event, ctx) => {
    await writeState("idle", ctx);
  });

  pi.on("agent_start", async (_event, ctx) => {
    await writeState("working", ctx);
  });

  pi.on("agent_settled", async (_event, ctx) => {
    await writeState("idle", ctx);
  });

  pi.on("session_shutdown", async () => {
    await removeState();
  });
}
