import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

import { getErrorMessage } from "@accel-os/shared/guards";

import { readHostConfig, validateHostConfig } from "../lib/host-config.ts";

const scriptsDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptsDirectory, "../..");
const dataDirectory = path.join(repositoryRoot, "dotfiles/.chezmoidata");

try {
  const config = await readHostConfig({
    packages: path.join(dataDirectory, "packages.yaml"),
    services: path.join(dataDirectory, "services.yaml"),
    hosts: path.join(dataDirectory, "hosts.yaml"),
    tlp: path.join(dataDirectory, "tlp.yaml"),
  });
  const errors = validateHostConfig(config);

  if (errors.length > 0) {
    console.error(
      `Host configuration validation failed:\n${errors.map((error) => `- ${error}`).join("\n")}`,
    );
    process.exitCode = 1;
  }
} catch (error) {
  console.error(`Host configuration validation failed: ${getErrorMessage(error)}`);
  process.exitCode = 1;
}
