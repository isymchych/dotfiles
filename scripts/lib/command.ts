import { spawnSync } from "node:child_process";

export function runCommand(command: string, args: readonly string[]): string {
  const result = spawnSync(command, [...args], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });

  if (result.error !== undefined) {
    throw result.error;
  }

  if (result.status !== 0) {
    const detail = result.stderr.trim();
    throw new Error(
      detail === ""
        ? `${command} exited with status ${String(result.status)}`
        : `${command} exited with status ${String(result.status)}: ${detail}`,
    );
  }

  return result.stdout;
}

export function runBestEffort(command: string, args: readonly string[]): void {
  spawnSync(command, [...args], { stdio: "ignore" });
}
