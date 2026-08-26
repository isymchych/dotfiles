import { spawn } from "node:child_process";
import type { ChildProcessWithoutNullStreams } from "node:child_process";
import { createReadStream, createWriteStream, readFileSync } from "node:fs";
import {
  chmod,
  copyFile,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import process from "node:process";
import { pipeline } from "node:stream/promises";
import { fileURLToPath, pathToFileURL } from "node:url";

import { getErrorMessage } from "@accel-os/shared/guards";
import { parseJsonWithSchema } from "@accel-os/shared/json";
import { Type } from "typebox";

type Mode = "history" | "templates" | "emoji";
type ModeDirection = "next" | "previous";
export type Action = "copy" | "save" | "delete" | "next-mode" | "previous-mode";

export type HistoryItem = {
  kind: "history";
  id: string;
};

export type TemplateItem = {
  kind: "template";
  path: string;
};

export type EmojiItem = {
  kind: "emoji";
  value: string;
};

export type ClipboardItem = HistoryItem | TemplateItem | EmojiItem;

export type HistoryMenuItem = {
  id: string;
  preview: string;
  imageExtension: string | null;
};

type Paths = {
  templatesDir: string;
  fuzzelConfig: string;
  thumbnailDir: string;
  lastSaveDirFile: string;
  runtimeDir: string;
  blobFile: string;
};

type Menu = {
  data: Buffer;
  templatePaths: string[];
  emojis: string[];
};

type CommandResult = {
  code: number | null;
  stdout: Buffer;
};

const IMAGE_PREVIEW_PATTERN = /binary.*(jpg|jpeg|png|bmp|gif|webp|tiff)/iu;
const MODES = ["history", "templates", "emoji"] as const satisfies readonly Mode[];
const TEMPLATES_DIR = fileURLToPath(new URL("../assets/mb-clipboard/templates/", import.meta.url));
const EMOJI_KEYWORDS = parseJsonWithSchema(
  readFileSync(fileURLToPath(import.meta.resolve("emojilib")), "utf8"),
  Type.Record(Type.String(), Type.Array(Type.String())),
  "emojilib dataset",
);

const MIME_EXTENSIONS: Readonly<Record<string, string>> = {
  "text/plain": "txt",
  "text/html": "html",
  "text/csv": "csv",
  "text/markdown": "md",
  "application/json": "json",
  "application/pdf": "pdf",
  "application/xml": "xml",
  "text/xml": "xml",
  "application/zip": "zip",
  "application/gzip": "gz",
  "application/x-tar": "tar",
  "image/png": "png",
  "image/jpeg": "jpg",
  "image/gif": "gif",
  "image/webp": "webp",
  "image/bmp": "bmp",
  "image/tiff": "tiff",
  "image/svg+xml": "svg",
  "audio/mpeg": "mp3",
  "audio/ogg": "ogg",
  "audio/wav": "wav",
  "audio/x-wav": "wav",
  "video/mp4": "mp4",
  "video/webm": "webm",
};

async function main(): Promise<number> {
  const paths = await createPaths();

  try {
    return await runInteractiveLoop(paths);
  } finally {
    await rm(paths.runtimeDir, { recursive: true, force: true });
  }
}

async function createPaths(): Promise<Paths> {
  const home = process.env["HOME"];
  if (home === undefined || home === "") {
    throw new Error("HOME must be set");
  }

  const configHome = process.env["XDG_CONFIG_HOME"] || path.join(home, ".config");
  const cacheHome = process.env["XDG_CACHE_HOME"] || path.join(home, ".cache");
  const configDir = path.join(configHome, "mb-clipboard");
  const cacheDir = path.join(cacheHome, "mb-clipboard");
  const thumbnailDir = path.join(cacheDir, "thumbnails");

  await mkdir(thumbnailDir, { recursive: true, mode: 0o700 });
  await Promise.all([chmod(cacheDir, 0o700), chmod(thumbnailDir, 0o700)]);

  const runtimeDir = await mkdtemp(path.join(tmpdir(), "mb-clipboard-"));
  await chmod(runtimeDir, 0o700);

  return {
    templatesDir: TEMPLATES_DIR,
    fuzzelConfig: path.join(configDir, "fuzzel.ini"),
    thumbnailDir,
    lastSaveDirFile: path.join(cacheDir, "last-save-dir"),
    runtimeDir,
    blobFile: path.join(runtimeDir, "blob"),
  };
}

async function runInteractiveLoop(paths: Paths): Promise<number> {
  let mode: Mode = "history";
  let modeDirection: ModeDirection = "next";

  while (true) {
    const menu = await buildMenu(mode, paths);

    if (menu.data.length === 0) {
      mode = moveMode(mode, modeDirection);
      continue;
    }

    const result = await showMenu(mode, menu.data, paths.fuzzelConfig);
    const action = actionForExitCode(result.code);
    if (action === null) {
      return 0;
    }

    if (action === "next-mode" || action === "previous-mode") {
      modeDirection = action === "next-mode" ? "next" : "previous";
      mode = moveMode(mode, modeDirection);
      continue;
    }

    if (!supportsAction(mode, action)) {
      continue;
    }

    const token = removeTrailingNewline(result.stdout.toString("utf8"));
    if (token === "") {
      continue;
    }

    const item = parseSelection(token, menu.templatePaths, menu.emojis);
    if (item === null) {
      if (action === "copy") {
        await notify("Clipboard", "Could not copy the selected item");
        return 1;
      }
      continue;
    }

    if (action === "copy") {
      if (!(await copyItem(item))) {
        await notify("Clipboard", "Could not copy the selected item");
        return 1;
      }
      return 0;
    }

    if (action === "save") {
      if (await saveItem(item, paths)) {
        return 0;
      }
      continue;
    }

    await deleteItem(item, paths);
  }
}

async function buildMenu(mode: Mode, paths: Paths): Promise<Menu> {
  if (mode === "history") {
    return buildHistoryMenu(paths);
  }

  return mode === "templates" ? buildTemplateMenu(paths.templatesDir) : buildEmojiMenu();
}

async function buildTemplateMenu(templatesDir: string): Promise<Menu> {
  let entries;
  try {
    entries = await readdir(templatesDir, { withFileTypes: true });
  } catch (error) {
    if (isErrnoException(error) && error.code === "ENOENT") {
      return { data: Buffer.alloc(0), templatePaths: [], emojis: [] };
    }
    throw error;
  }

  const templatePaths = entries
    .filter((entry) => entry.isFile() && !entry.name.startsWith("."))
    .map((entry) => path.join(templatesDir, entry.name))
    .sort();

  const rows = templatePaths.map((templatePath, index) => {
    const name = path.basename(templatePath).replaceAll("\t", " ");
    return serializeMenuRow(`t:${index}`, name);
  });

  return { data: Buffer.from(rows.join("")), templatePaths, emojis: [] };
}

async function buildHistoryMenu(paths: Paths): Promise<Menu> {
  let result: CommandResult;
  try {
    result = await runCommand("cliphist", ["list"]);
  } catch {
    return { data: Buffer.alloc(0), templatePaths: [], emojis: [] };
  }

  if (result.code !== 0) {
    return { data: Buffer.alloc(0), templatePaths: [], emojis: [] };
  }

  const rows: string[] = [];
  const historyIds = new Set<string>();

  for (const item of parseHistoryList(result.stdout.toString("utf8"))) {
    const { id } = item;
    historyIds.add(id);
    const previewIcon =
      item.imageExtension === null ? null : await ensurePreviewIcon(id, item.imageExtension, paths);
    rows.push(serializeMenuRow(`h:${id}`, item.preview, previewIcon));
  }

  await cleanThumbnails(historyIds, paths.thumbnailDir);
  return { data: Buffer.from(rows.join("")), templatePaths: [], emojis: [] };
}

function buildEmojiMenu(): Menu {
  const entries = Object.entries(EMOJI_KEYWORDS);
  const emojis = entries.map(([emoji]) => emoji);
  const rows = entries.map(([emoji, keywords], index) =>
    serializeMenuRow(`e:${index}`, `${emoji}  ${keywords.join(" ").replaceAll("\t", " ")}`),
  );

  return { data: Buffer.from(rows.join("")), templatePaths: [], emojis };
}

export function parseHistoryList(raw: string): HistoryMenuItem[] {
  const items: HistoryMenuItem[] = [];

  for (const line of raw.split("\n")) {
    const separator = line.indexOf("\t");
    if (separator === -1) {
      continue;
    }

    const id = line.slice(0, separator);
    if (!/^\d+$/u.test(id)) {
      continue;
    }

    const preview = line.slice(separator + 1).replaceAll("\t", " ");
    const imageMatch = IMAGE_PREVIEW_PATTERN.exec(preview);
    const imageExtension = imageMatch?.[1]?.toLowerCase() ?? null;

    items.push({ id, preview, imageExtension });
  }

  return items;
}

export function serializeMenuRow(
  token: string,
  display: string,
  iconPath: string | null = null,
): string {
  return iconPath === null
    ? `${token}\t${display}\n`
    : `${token}\t${display}\0icon\x1f${iconPath}\n`;
}

async function ensurePreviewIcon(
  id: string,
  extension: string,
  paths: Paths,
): Promise<string | null> {
  const thumbnail = path.join(paths.thumbnailDir, `${id}.${extension}`);

  if (!(await isNonemptyFile(thumbnail))) {
    const temporaryThumbnail = path.join(paths.runtimeDir, `thumbnail-${id}`);
    if (await decodeHistoryToFile(id, temporaryThumbnail)) {
      await chmod(temporaryThumbnail, 0o600);
      await rename(temporaryThumbnail, thumbnail);
    } else {
      await rm(temporaryThumbnail, { force: true });
    }
  }

  if (!(await isNonemptyFile(thumbnail))) {
    return null;
  }

  const previewIcon = path.join(paths.thumbnailDir, `${id}.svg`);
  const temporaryPreviewIcon = path.join(paths.runtimeDir, `preview-${id}.svg`);
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <image href="${escapeXml(thumbnail)}" width="100" height="100" preserveAspectRatio="xMidYMid meet"/>
</svg>
`;

  await writeFile(temporaryPreviewIcon, svg, { mode: 0o600 });

  if (!(await filesEqual(temporaryPreviewIcon, previewIcon))) {
    await rename(temporaryPreviewIcon, previewIcon);
  } else {
    await rm(temporaryPreviewIcon);
  }

  return previewIcon;
}

async function cleanThumbnails(
  historyIds: ReadonlySet<string>,
  thumbnailDir: string,
): Promise<void> {
  const entries = await readdir(thumbnailDir, { withFileTypes: true });
  await Promise.all(
    entries.map(async (entry) => {
      const id = entry.name.split(".", 1)[0] ?? "";
      if (!historyIds.has(id)) {
        await rm(path.join(thumbnailDir, entry.name), { force: true });
      }
    }),
  );
}

async function showMenu(mode: Mode, menu: Buffer, fuzzelConfig: string): Promise<CommandResult> {
  const presentation =
    mode === "history"
      ? {
          prompt: "Clipboard > ",
          placeholder: "Search clipboard...",
          message:
            "Enter: copy | Ctrl+T/Ctrl+Shift+T: switch mode | Ctrl+S: save as... | Shift+Delete: delete",
        }
      : mode === "templates"
        ? {
            prompt: "Templates > ",
            placeholder: "Search templates...",
            message: "Enter: copy | Ctrl+T/Ctrl+Shift+T: switch mode | Ctrl+S: save as...",
          }
        : {
            prompt: "Emoji > ",
            placeholder: "Search emoji...",
            message: "Enter: copy | Ctrl+T/Ctrl+Shift+T: switch mode",
          };

  return runCommand(
    "fuzzel",
    [
      "--dmenu",
      `--config=${fuzzelConfig}`,
      `--prompt=${presentation.prompt}`,
      `--placeholder=${presentation.placeholder}`,
      `--mesg=${presentation.message}`,
      "--counter",
      ...(mode === "history" ? ["--no-sort"] : []),
      "--only-match",
      "--with-nth=2",
      "--accept-nth=1",
    ],
    menu,
  );
}

export function actionForExitCode(code: number | null): Action | null {
  switch (code) {
    case 0:
      return "copy";
    case 10:
      return "save";
    case 11:
      return "delete";
    case 12:
      return "next-mode";
    case 13:
      return "previous-mode";
    default:
      return null;
  }
}

export function parseSelection(
  token: string,
  templatePaths: readonly string[],
  emojis: readonly string[] = [],
): ClipboardItem | null {
  const historyMatch = /^h:(\d+)$/u.exec(token);
  if (historyMatch?.[1] !== undefined) {
    return { kind: "history", id: historyMatch[1] };
  }

  const templateMatch = /^t:(\d+)$/u.exec(token);
  if (templateMatch?.[1] === undefined) {
    const emojiMatch = /^e:(\d+)$/u.exec(token);
    if (emojiMatch?.[1] === undefined) {
      return null;
    }

    const index = Number(emojiMatch[1]);
    if (!Number.isSafeInteger(index)) {
      return null;
    }

    const value = emojis[index];
    return value === undefined ? null : { kind: "emoji", value };
  }

  const index = Number(templateMatch[1]);
  if (!Number.isSafeInteger(index)) {
    return null;
  }

  const templatePath = templatePaths[index];
  if (templatePath === undefined) {
    return null;
  }

  return { kind: "template", path: templatePath };
}

async function copyItem(item: ClipboardItem): Promise<boolean> {
  if (item.kind === "emoji") {
    try {
      return (await runCommand("wl-copy", [], Buffer.from(item.value))).code === 0;
    } catch {
      return false;
    }
  }

  if (item.kind === "template") {
    return pipeFileToCommand(item.path, "wl-copy", []);
  }

  return pipeHistoryToClipboard(item.id);
}

async function saveItem(item: ClipboardItem, paths: Paths): Promise<boolean> {
  if (!(await materialize(item, paths.blobFile))) {
    await notify("Clipboard", "Could not decode the selected item");
    return false;
  }

  const mime = await detectMime(paths.blobFile);
  const suggestedName =
    item.kind === "template"
      ? path.basename(item.path)
      : `clipboard-${formatTimestamp(new Date())}.${extensionForMime(mime)}`;
  const saveDir = await findSaveDirectory(paths.lastSaveDirFile);
  const result = await runCommand("zenity", [
    "--file-selection",
    "--save",
    `--title=Save clipboard item (${mime})`,
    `--filename=${path.join(saveDir, suggestedName)}`,
  ]);

  if (result.code !== 0) {
    return false;
  }

  const destination = removeTrailingNewline(result.stdout.toString("utf8"));
  if (destination === "") {
    return false;
  }

  try {
    await pipeline(createReadStream(paths.blobFile), createWriteStream(destination));
  } catch {
    await notify("Clipboard save failed", destination);
    return false;
  }

  const temporaryState = path.join(paths.runtimeDir, "last-save-dir");
  await writeFile(temporaryState, `${path.dirname(destination)}\n`, { mode: 0o600 });
  await rename(temporaryState, paths.lastSaveDirFile);
  await notify("Clipboard item saved", destination);
  return true;
}

async function materialize(item: ClipboardItem, destination: string): Promise<boolean> {
  if (item.kind === "history") {
    return decodeHistoryToFile(item.id, destination);
  }

  if (item.kind === "emoji") {
    try {
      await writeFile(destination, item.value, { mode: 0o600 });
      return true;
    } catch {
      return false;
    }
  }

  try {
    await copyFile(item.path, destination);
    return true;
  } catch {
    return false;
  }
}

async function deleteItem(item: ClipboardItem, paths: Paths): Promise<void> {
  if (item.kind === "template") {
    await notify("Clipboard template", `Templates are managed in ${paths.templatesDir}`);
    return;
  }

  if (item.kind === "emoji") {
    return;
  }

  const confirmation = await runCommand("zenity", [
    "--question",
    "--title=Delete clipboard entry?",
    "--text=Permanently delete the selected entry from clipboard history?",
    "--ok-label=Delete",
    "--cancel-label=Cancel",
  ]);
  if (confirmation.code !== 0) {
    return;
  }

  const result = await runCommand("cliphist", ["delete"], Buffer.from(`${item.id}\t\n`));
  if (result.code === 0) {
    await removeThumbnailVariants(item.id, paths.thumbnailDir);
  }
}

async function removeThumbnailVariants(id: string, thumbnailDir: string): Promise<void> {
  const entries = await readdir(thumbnailDir);
  await Promise.all(
    entries
      .filter((name) => name.startsWith(`${id}.`))
      .map(async (name) => rm(path.join(thumbnailDir, name), { force: true })),
  );
}

async function detectMime(filePath: string): Promise<string> {
  try {
    const result = await runCommand("file", ["--brief", "--mime-type", "--", filePath]);
    if (result.code === 0) {
      const mime = result.stdout.toString("utf8").trim();
      if (mime !== "") {
        return mime;
      }
    }
  } catch {
    // Match the shell implementation's application/octet-stream fallback.
  }

  return "application/octet-stream";
}

export function extensionForMime(mime: string): string {
  return MIME_EXTENSIONS[mime] ?? "bin";
}

async function findSaveDirectory(lastSaveDirFile: string): Promise<string> {
  const home = process.env["HOME"];
  if (home === undefined || home === "") {
    throw new Error("HOME must be set");
  }

  const downloads = path.join(home, "Downloads");
  let saveDir = (await isDirectory(downloads)) ? downloads : home;

  try {
    const stored = (await readFile(lastSaveDirFile, "utf8")).split("\n", 1)[0] ?? "";
    if (stored !== "" && (await isDirectory(stored))) {
      saveDir = stored;
    }
  } catch (error) {
    if (!(isErrnoException(error) && error.code === "ENOENT")) {
      throw error;
    }
  }

  return saveDir;
}

async function decodeHistoryToFile(id: string, destination: string): Promise<boolean> {
  const child = spawnCommand("cliphist", ["decode"]);
  const stderrPromise = collectStream(child.stderr);
  child.stdin.end(`${id}\t\n`);

  try {
    const [exit] = await Promise.all([
      waitForExit(child),
      pipeline(child.stdout, createWriteStream(destination, { mode: 0o600 })),
    ]);
    await stderrPromise;
    return exit.code === 0;
  } catch {
    await rm(destination, { force: true });
    return false;
  }
}

async function pipeHistoryToClipboard(id: string): Promise<boolean> {
  const decode = spawnCommand("cliphist", ["decode"]);
  const copy = spawnCommand("wl-copy", []);
  const stderrPromises = [collectStream(decode.stderr), collectStream(copy.stderr)];
  decode.stdin.end(`${id}\t\n`);

  try {
    const [decodeExit, copyExit] = await Promise.all([
      waitForExit(decode),
      waitForExit(copy),
      pipeline(decode.stdout, copy.stdin),
    ]);
    await Promise.all(stderrPromises);
    return decodeExit.code === 0 && copyExit.code === 0;
  } catch {
    decode.kill();
    copy.kill();
    return false;
  }
}

async function pipeFileToCommand(
  filePath: string,
  command: string,
  args: readonly string[],
): Promise<boolean> {
  const child = spawnCommand(command, args);
  const stderrPromise = collectStream(child.stderr);

  try {
    const [exit] = await Promise.all([
      waitForExit(child),
      pipeline(createReadStream(filePath), child.stdin),
    ]);
    await stderrPromise;
    return exit.code === 0;
  } catch {
    child.kill();
    return false;
  }
}

async function runCommand(
  command: string,
  args: readonly string[],
  input?: Buffer,
): Promise<CommandResult> {
  const child = spawnCommand(command, args);
  const stdoutPromise = collectStream(child.stdout);
  const stderrPromise = collectStream(child.stderr);
  child.stdin.end(input);

  const [exit, stdout] = await Promise.all([waitForExit(child), stdoutPromise, stderrPromise]);
  return { code: exit.code, stdout };
}

function spawnCommand(command: string, args: readonly string[]): ChildProcessWithoutNullStreams {
  const child = spawn(command, args, { stdio: ["pipe", "pipe", "pipe"] });
  child.stdin.on("error", () => {
    // Command exit status is the authoritative result; ignore a concurrent EPIPE.
  });
  return child;
}

async function waitForExit(
  child: ChildProcessWithoutNullStreams,
): Promise<{ code: number | null; signal: NodeJS.Signals | null }> {
  return new Promise((resolve, reject) => {
    child.once("error", reject);
    child.once("close", (code, signal) => resolve({ code, signal }));
  });
}

async function collectStream(stream: NodeJS.ReadableStream): Promise<Buffer> {
  const chunks: Buffer[] = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
}

async function notify(title: string, message: string): Promise<void> {
  try {
    await runCommand("notify-send", ["--app-name=mb-clipboard", title, message]);
  } catch {
    // Notifications are best-effort and must not change clipboard behavior.
  }
}

async function isDirectory(filePath: string): Promise<boolean> {
  try {
    return (await stat(filePath)).isDirectory();
  } catch (error) {
    if (isErrnoException(error) && error.code === "ENOENT") {
      return false;
    }
    throw error;
  }
}

async function isNonemptyFile(filePath: string): Promise<boolean> {
  try {
    return (await stat(filePath)).size > 0;
  } catch (error) {
    if (isErrnoException(error) && error.code === "ENOENT") {
      return false;
    }
    throw error;
  }
}

async function filesEqual(leftPath: string, rightPath: string): Promise<boolean> {
  try {
    const [left, right] = await Promise.all([readFile(leftPath), readFile(rightPath)]);
    return left.equals(right);
  } catch (error) {
    if (isErrnoException(error) && error.code === "ENOENT") {
      return false;
    }
    throw error;
  }
}

function escapeXml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll('"', "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function removeTrailingNewline(value: string): string {
  return value.endsWith("\n") ? value.slice(0, -1).replace(/\r$/u, "") : value;
}

function formatTimestamp(date: Date): string {
  const pad = (value: number): string => String(value).padStart(2, "0");
  return `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}-${pad(
    date.getHours(),
  )}${pad(date.getMinutes())}${pad(date.getSeconds())}`;
}

function moveMode(mode: Mode, direction: ModeDirection): Mode {
  const currentIndex = MODES.indexOf(mode);
  const offset = direction === "next" ? 1 : -1;
  return MODES[(currentIndex + offset + MODES.length) % MODES.length] ?? MODES[0];
}

function supportsAction(mode: Mode, action: Action): boolean {
  return mode !== "emoji" || action === "copy";
}

function isErrnoException(error: unknown): error is NodeJS.ErrnoException {
  return error instanceof Error && "code" in error;
}

if (process.argv[1] !== undefined && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main()
    .then((code) => {
      process.exitCode = code;
    })
    .catch((error: unknown) => {
      process.stderr.write(`${getErrorMessage(error)}\n`);
      process.exitCode = 1;
    });
}
