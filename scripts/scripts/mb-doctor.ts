import { constants } from "node:fs";
import { access, lstat, readFile, readdir, stat } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { fileURLToPath, pathToFileURL } from "node:url";

import { getErrorMessage } from "@accel-os/shared/guards";
import { runCommand } from "@accel-os/shared/process";

import { formatDoctorResults, runDoctor, type DoctorDependencies } from "../lib/doctor.ts";
import { readHostConfig, resolveHostState, validateHostConfig } from "../lib/host-config.ts";

const scriptsDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptsDirectory, "../..");
const dataDirectory = path.join(repositoryRoot, "dotfiles/.chezmoidata");

const usage = `Usage: mb-doctor

Verify that this host satisfies its declared accel-os configuration.
The command is read-only; use chezmoi apply to repair reported drift.
`;

async function readText(filePath: string): Promise<string | null> {
  try {
    return await readFile(filePath, "utf8");
  } catch (error) {
    if (typeof error === "object" && error !== null && "code" in error && error.code === "ENOENT") {
      return null;
    }
    throw error;
  }
}

async function isExecutable(filePath: string): Promise<boolean> {
  try {
    const metadata = await stat(filePath);
    if (!metadata.isFile()) {
      return false;
    }
    await access(filePath, constants.X_OK);
    return true;
  } catch {
    return false;
  }
}

const dependencies: DoctorDependencies = {
  readText,
  async inspectPath(filePath) {
    try {
      const metadata = await lstat(filePath);
      return {
        uid: metadata.uid,
        gid: metadata.gid,
        mode: metadata.mode,
        isFile: metadata.isFile(),
        isSymbolicLink: metadata.isSymbolicLink(),
      };
    } catch (error) {
      if (
        typeof error === "object" &&
        error !== null &&
        "code" in error &&
        error.code === "ENOENT"
      ) {
        return null;
      }
      throw error;
    }
  },
  async listFiles(directory) {
    return readdir(directory);
  },
  isExecutable,
  runCommand,
};

async function main(args: readonly string[]): Promise<void> {
  if (args.includes("-h") || args.includes("--help")) {
    process.stdout.write(usage);
    return;
  }
  if (args.length > 0) {
    throw new Error(`Unexpected argument: ${args[0] ?? ""}`);
  }

  const config = await readHostConfig({
    packages: path.join(dataDirectory, "packages.yaml"),
    services: path.join(dataDirectory, "services.yaml"),
    hosts: path.join(dataDirectory, "hosts.yaml"),
    tlp: path.join(dataDirectory, "tlp.yaml"),
  });
  const configErrors = validateHostConfig(config);
  if (configErrors.length > 0) {
    throw new Error(`Invalid host configuration:\n${configErrors.join("\n")}`);
  }

  const hostname = os.hostname();
  const results = await runDoctor(
    {
      state: resolveHostState(config, hostname),
      repositoryRoot,
      homeDirectory: os.homedir(),
      username: os.userInfo().username,
      platform: process.platform,
      environment: process.env,
    },
    dependencies,
  );

  process.stdout.write(formatDoctorResults(results));
  if (results.some((result) => result.status === "fail")) {
    process.exitCode = 1;
  }
}

if (process.argv[1] !== undefined && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv.slice(2)).catch((error: unknown) => {
    process.stderr.write(`${getErrorMessage(error)}\n${usage}`);
    process.exitCode = 1;
  });
}
