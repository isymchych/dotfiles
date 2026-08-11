import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import { createReadToolDefinition, defineTool } from "@earendil-works/pi-coding-agent";
import { stripTerminalSequences } from "@earendil-works/pi-tui";

import {
  emptyCompactText,
  formatRelativePath,
  pluralize,
  rememberCollapsedSummary,
  renderCollapsedCall,
  setCompactText,
} from "../shared/compact-tool-render.ts";
import { executeReadTool, type EnhancedReadDetails, type ReadTargetDetails } from "./execute.ts";
import { readToolSchema, type ReadTargetInput } from "./schema.ts";

/**
 * Replaces Pi's single-file read tool with one canonical reader for files, images, and directories.
 * The tool accepts ordered batches, divides the output budget fairly across targets, and owns its
 * compact TUI rendering so execution and presentation cannot be split across competing `read`
 * overrides.
 */

const toolCache = new Map<string, ReturnType<typeof createReadToolDefinition>>();

function getBuiltInRead(cwd: string): ReturnType<typeof createReadToolDefinition> {
  const cached = toolCache.get(cwd);
  if (cached !== undefined) {
    return cached;
  }
  const tool = createReadToolDefinition(cwd);
  toolCache.set(cwd, tool);
  return tool;
}

function formatTarget(
  target: ReadTargetInput,
  cwd: string,
  showLineNumbers: boolean | undefined,
): string {
  const normalizedPath = target.path.startsWith("@") ? target.path.slice(1) : target.path;
  let formatted = formatRelativePath(normalizedPath, cwd);
  if (target.offset !== undefined || target.limit !== undefined) {
    const startLine = target.offset ?? 1;
    const endLine = target.limit !== undefined ? startLine + target.limit - 1 : undefined;
    formatted += endLine !== undefined ? `:${startLine}-${endLine}` : `:${startLine}`;
  }
  if (showLineNumbers === true) {
    formatted += " [numbered]";
  }
  return formatted;
}

function formatCallTarget(
  targets: readonly ReadTargetInput[],
  cwd: string,
  showLineNumbers: boolean | undefined,
  recursive: boolean | undefined,
): string {
  const visible = targets.slice(0, 2).map((target) => formatTarget(target, cwd, showLineNumbers));
  let label = visible.join(", ");
  if (targets.length > visible.length) {
    label += ` +${targets.length - visible.length}`;
  }
  if (recursive === true) {
    label += " [recursive]";
  }
  return label;
}

function countKind(targets: readonly ReadTargetDetails[], kind: ReadTargetDetails["kind"]): number {
  return targets.filter((target) => target.kind === kind).length;
}

function summarizeDetails(details: EnhancedReadDetails): {
  status: "success" | "warning";
  label: string;
} {
  const errors = countKind(details.targets, "error");
  const truncated =
    details.targets.some((target) => target.truncated === true) ||
    details.directoryEntryLimitReached === true;

  let label: string;
  if (details.targets.length === 1) {
    const [target] = details.targets;
    if (target === undefined) {
      label = "empty";
    } else if (target.kind === "directory") {
      label = pluralize(target.entryCount ?? 0, "entry", "entries");
    } else if (target.kind === "image") {
      label = "image loaded";
    } else if (target.kind === "file") {
      label = pluralize(target.lineCount ?? 0, "line", "lines");
    } else {
      label = "failed";
    }
  } else {
    label = pluralize(details.targets.length, "target", "targets");
    if (errors > 0) {
      label += `, ${errors} failed`;
    }
  }

  if (truncated) {
    label += " [truncated]";
  }
  return { status: errors > 0 || truncated ? "warning" : "success", label };
}

function getTextOutput(content: readonly { type: string; text?: string }[]): string {
  return content
    .filter((block) => block.type === "text" && typeof block.text === "string")
    .map((block) => block.text ?? "")
    .join("\n");
}

export function renderExpandedText(
  content: readonly { type: string; text?: string }[],
  theme: Theme,
): string {
  const output = stripTerminalSequences(getTextOutput(content));
  return output.length === 0 ? "" : `\n${theme.fg("toolOutput", output)}`;
}

function renderExpandedResult(
  content: readonly { type: string; text?: string }[],
  theme: Theme,
  lastComponent: unknown,
): ReturnType<typeof setCompactText> {
  return setCompactText(lastComponent, renderExpandedText(content, theme));
}

export default function readToolExtension(pi: ExtensionAPI): void {
  const tool = defineTool<typeof readToolSchema, EnhancedReadDetails>({
    name: "read",
    label: "read",
    description:
      "Read one or more files or directories. Text files support per-target offset/limit and optional " +
      "line numbers. Images are returned as attachments. Directories include entry type, size, and " +
      "symlink target, and can optionally be listed recursively without following directory symlinks. " +
      "The complete call is limited to 2000 lines or 50KB, divided fairly across targets. Input shape: " +
      "{ targets: [{ path, offset?, limit? }], recursive?, max_depth?, show_line_numbers? }. Put offset " +
      "and limit inside each target, never at the root; for example: { targets: [{ path: 'justfile', " +
      "offset: 1, limit: 160 }] }.",
    promptSnippet: "Read files or list directory contents",
    promptGuidelines: [
      "Use read for one or more known file or directory paths instead of cat, sed, or ls.",
      "Put path, offset, and limit inside each targets item; never send path, offset, or limit at the root.",
      "Use read with show_line_numbers=true when exact file line references matter.",
      "Use read recursive directory listing only when the directory tree itself is needed; use Tilth for repository discovery and structural code exploration.",
    ],
    parameters: readToolSchema,
    renderShell: "self",
    async execute(toolCallId, params, signal, _onUpdate, ctx) {
      const builtIn = getBuiltInRead(ctx.cwd);
      return executeReadTool(params, ctx.cwd, signal, async (target, targetSignal) =>
        builtIn.execute(toolCallId, target, targetSignal, undefined, ctx),
      );
    },
    renderCall(args, theme, context) {
      return renderCollapsedCall(
        context.lastComponent,
        theme,
        context,
        "read",
        formatCallTarget(args.targets, context.cwd, args.show_line_numbers, args.recursive),
      );
    },
    renderResult(result, options, theme, context) {
      if (options.expanded || options.isPartial || context.isError) {
        return renderExpandedResult(result.content, theme, context.lastComponent);
      }

      rememberCollapsedSummary(context, summarizeDetails(result.details));
      return emptyCompactText(context.lastComponent);
    },
  });

  pi.registerTool(tool);
}
