import { constants } from "node:fs";
import type { Stats } from "node:fs";
import { lstat, mkdir, open, rename, unlink } from "node:fs/promises";
import { dirname, join, parse, relative, sep } from "node:path";
import process from "node:process";

import { withFileMutationQueue } from "@earendil-works/pi-coding-agent";

const NO_FOLLOW_FLAG = constants.O_NOFOLLOW;
// These Node file-open flags occupy distinct bit positions.
const CREATE_EXCLUSIVE_NOFOLLOW_FLAGS =
  constants.O_WRONLY + constants.O_CREAT + constants.O_EXCL + NO_FOLLOW_FLAG;

export interface Workspace {
  readText: (absolutePath: string) => Promise<string>;
  createText: (absolutePath: string, content: string) => Promise<void>;
  replaceText: (absolutePath: string, content: string) => Promise<void>;
  deleteFile: (absolutePath: string) => Promise<void>;
  renameFile: (fromPath: string, toPath: string) => Promise<void>;
  exists: (absolutePath: string) => Promise<boolean>;
}

export class WorkspaceMutationError extends Error {
  public readonly stateUnknown: boolean;

  public constructor(message: string, stateUnknown: boolean, cause?: unknown) {
    super(message, cause === undefined ? undefined : { cause });
    this.name = "WorkspaceMutationError";
    this.stateUnknown = stateUnknown;
  }
}

function isNotFound(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    (error as { code?: unknown }).code === "ENOENT"
  );
}

async function getPathStats(absolutePath: string): Promise<Stats | undefined> {
  try {
    return await lstat(absolutePath);
  } catch (error) {
    if (isNotFound(error)) {
      return undefined;
    }
    throw error;
  }
}

async function assertNoSymbolicLinkComponents(absolutePath: string): Promise<void> {
  const root = parse(absolutePath).root;
  const pathComponents = relative(root, absolutePath).split(sep).filter(Boolean);
  let currentPath = root;

  for (const component of pathComponents) {
    currentPath = join(currentPath, component);
    const stats = await getPathStats(currentPath);
    if (stats?.isSymbolicLink()) {
      throw new Error(`Refusing to mutate path through symbolic link: ${currentPath}`);
    }
  }
}

async function assertRegularFile(absolutePath: string): Promise<void> {
  await assertNoSymbolicLinkComponents(absolutePath);
  const stats = await getPathStats(absolutePath);
  if (stats === undefined) {
    throw new Error(`File not found: ${absolutePath}`);
  }
  if (stats.isSymbolicLink()) {
    throw new Error(`Refusing to mutate symbolic link: ${absolutePath}`);
  }
  if (!stats.isFile()) {
    throw new Error(`Refusing to mutate non-regular file: ${absolutePath}`);
  }
}

async function readRegularFile(absolutePath: string): Promise<string> {
  await assertRegularFile(absolutePath);
  const handle = await open(absolutePath, constants.O_RDONLY + NO_FOLLOW_FLAG);
  try {
    return await handle.readFile("utf-8");
  } finally {
    await handle.close();
  }
}

async function createRegularFile(absolutePath: string, content: string): Promise<void> {
  await assertNoSymbolicLinkComponents(absolutePath);
  const stats = await getPathStats(absolutePath);
  if (stats !== undefined) {
    throw new Error(`File already exists: ${absolutePath}`);
  }

  await mkdir(dirname(absolutePath), { recursive: true });
  let handle;
  try {
    handle = await open(absolutePath, CREATE_EXCLUSIVE_NOFOLLOW_FLAGS);
  } catch (error) {
    throw new WorkspaceMutationError(`Failed to create file ${absolutePath}`, false, error);
  }

  try {
    await handle.writeFile(content, "utf-8");
    await handle.close();
  } catch (error) {
    await handle.close().catch(() => undefined);
    const removed = await unlink(absolutePath)
      .then(() => true)
      .catch(() => false);
    throw new WorkspaceMutationError(`Failed to create file ${absolutePath}`, !removed, error);
  }
}

async function replaceRegularFile(absolutePath: string, content: string): Promise<void> {
  await assertRegularFile(absolutePath);
  const tempPath = `${absolutePath}.tmp.${process.pid}.${Math.random().toString(16).slice(2)}`;
  let handle;

  try {
    handle = await open(tempPath, CREATE_EXCLUSIVE_NOFOLLOW_FLAGS);
    await handle.writeFile(content, "utf-8");
    await handle.close();
  } catch (error) {
    await handle?.close().catch(() => undefined);
    await unlink(tempPath).catch(() => undefined);
    throw new WorkspaceMutationError(
      `Failed to write replacement for ${absolutePath}`,
      false,
      error,
    );
  }

  try {
    await rename(tempPath, absolutePath);
  } catch (error) {
    const removed = await unlink(tempPath)
      .then(() => true)
      .catch(() => false);
    throw new WorkspaceMutationError(`Failed to replace file ${absolutePath}`, !removed, error);
  }
}

async function renameRegularFile(fromPath: string, toPath: string): Promise<void> {
  await assertRegularFile(fromPath);
  await assertNoSymbolicLinkComponents(toPath);
  if ((await getPathStats(toPath)) !== undefined) {
    throw new Error(`Move destination already exists: ${toPath}`);
  }
  await mkdir(dirname(toPath), { recursive: true });

  try {
    await rename(fromPath, toPath);
  } catch (error) {
    throw new WorkspaceMutationError(`Failed to move ${fromPath} to ${toPath}`, true, error);
  }
}

export function createRealWorkspace(): Workspace {
  return {
    readText: readRegularFile,
    createText: createRegularFile,
    replaceText: replaceRegularFile,
    deleteFile: async (absolutePath: string) => {
      await assertRegularFile(absolutePath);
      await unlink(absolutePath);
    },
    renameFile: renameRegularFile,
    exists: async (absolutePath: string) => {
      await assertNoSymbolicLinkComponents(absolutePath);
      return (await getPathStats(absolutePath)) !== undefined;
    },
  };
}

export function createVirtualWorkspace(cwd: string): Workspace {
  const state = new Map<string, string | null>();

  async function ensureLoaded(absolutePath: string): Promise<void> {
    if (state.has(absolutePath)) {
      return;
    }

    try {
      state.set(absolutePath, await readRegularFile(absolutePath));
    } catch (error) {
      if (
        isNotFound(error) ||
        (error instanceof Error && error.message.startsWith("File not found:"))
      ) {
        state.set(absolutePath, null);
        return;
      }
      throw error;
    }
  }

  return {
    readText: async (absolutePath: string) => {
      await ensureLoaded(absolutePath);
      const content = state.get(absolutePath);
      if (content === null || content === undefined) {
        throw new Error(`File not found: ${absolutePath.replace(`${cwd}/`, "")}`);
      }
      return content;
    },
    createText: async (absolutePath: string, content: string) => {
      await ensureLoaded(absolutePath);
      if (state.get(absolutePath) !== null) {
        throw new Error(`File already exists: ${absolutePath.replace(`${cwd}/`, "")}`);
      }
      state.set(absolutePath, content);
    },
    replaceText: async (absolutePath: string, content: string) => {
      await ensureLoaded(absolutePath);
      if (state.get(absolutePath) === null) {
        throw new Error(`File not found: ${absolutePath.replace(`${cwd}/`, "")}`);
      }
      state.set(absolutePath, content);
    },
    deleteFile: async (absolutePath: string) => {
      await ensureLoaded(absolutePath);
      if (state.get(absolutePath) === null) {
        throw new Error(`File not found: ${absolutePath.replace(`${cwd}/`, "")}`);
      }
      state.set(absolutePath, null);
    },
    renameFile: async (fromPath: string, toPath: string) => {
      await ensureLoaded(fromPath);
      await ensureLoaded(toPath);
      const content = state.get(fromPath);
      if (content === null || content === undefined) {
        throw new Error(`File not found: ${fromPath.replace(`${cwd}/`, "")}`);
      }
      if (state.get(toPath) !== null) {
        throw new Error(`Move destination already exists: ${toPath.replace(`${cwd}/`, "")}`);
      }
      state.set(toPath, content);
      state.set(fromPath, null);
    },
    exists: async (absolutePath: string) => {
      await ensureLoaded(absolutePath);
      return state.get(absolutePath) !== null;
    },
  };
}

export async function withWorkspaceLocks<T>(
  absolutePaths: readonly string[],
  fn: () => Promise<T>,
): Promise<T> {
  let run: () => Promise<T> = fn;

  for (let index = absolutePaths.length - 1; index >= 0; index -= 1) {
    const absolutePath = absolutePaths[index];
    if (absolutePath === undefined) {
      continue;
    }

    const nextRun = run;
    run = async (): Promise<T> => withFileMutationQueue(absolutePath, nextRun);
  }

  return run();
}
