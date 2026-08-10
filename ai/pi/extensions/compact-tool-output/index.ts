import type {
  ExtensionAPI,
  FindToolDetails,
  GrepToolDetails,
  LsToolDetails,
} from "@earendil-works/pi-coding-agent";
import {
  createFindToolDefinition,
  createGrepToolDefinition,
  createLsToolDefinition,
  createWriteToolDefinition,
} from "@earendil-works/pi-coding-agent";

import {
  emptyCompactText,
  formatRelativePath,
  pluralize,
  rememberCollapsedSummary,
  renderCollapsedCall,
} from "../shared/compact-tool-render.ts";

/**
 * Dense collapsed rendering for Pi's built-in `find`, `grep`, `ls`, and `write` tools.
 *
 * Execution still delegates to Pi's built-ins. The collapsed TUI view is reduced to a single
 * self-rendered line per tool row; expanded and error rendering still delegate to Pi's built-ins.
 * `read` is owned by the read-tool extension; `bash` and `edit` are intentionally left unchanged.
 */

type FindToolDefinition = ReturnType<typeof createFindToolDefinition>;
type GrepToolDefinition = ReturnType<typeof createGrepToolDefinition>;
type LsToolDefinition = ReturnType<typeof createLsToolDefinition>;
type WriteToolDefinition = ReturnType<typeof createWriteToolDefinition>;

interface BuiltInTools {
  find: FindToolDefinition;
  grep: GrepToolDefinition;
  ls: LsToolDefinition;
  write: WriteToolDefinition;
}

function countLines(text: string): number {
  if (text.length === 0) {
    return 0;
  }
  return text.split("\n").length;
}

function countNonEmptyLines(text: string): number {
  if (text.length === 0) {
    return 0;
  }
  return text.split("\n").filter((line) => line.length > 0).length;
}

function getFirstTextBlock(content: readonly { type: string }[]): string | undefined {
  for (const block of content) {
    if (block.type === "text" && "text" in block && typeof block.text === "string") {
      return block.text;
    }
  }
  return undefined;
}

function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) {
    return text;
  }
  return `${text.slice(0, Math.max(0, maxLength - 3))}...`;
}

function truncationSuffix(truncated: boolean): string {
  return truncated ? " [truncated]" : "";
}

function firstLine(text: string): string {
  const [line = ""] = text.split("\n", 1);
  return line;
}

const toolCache = new Map<string, BuiltInTools>();

function createBuiltInTools(cwd: string): BuiltInTools {
  return {
    find: createFindToolDefinition(cwd),
    grep: createGrepToolDefinition(cwd),
    ls: createLsToolDefinition(cwd),
    write: createWriteToolDefinition(cwd),
  };
}

function getBuiltInTools(cwd: string): BuiltInTools {
  const cached = toolCache.get(cwd);
  if (cached !== undefined) {
    return cached;
  }

  const tools = createBuiltInTools(cwd);
  toolCache.set(cwd, tools);
  return tools;
}

function registerFindTool(pi: ExtensionAPI, startupTools: BuiltInTools): void {
  const tool: FindToolDefinition = {
    ...startupTools.find,
    renderShell: "self",
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return getBuiltInTools(ctx.cwd).find.execute(toolCallId, params, signal, onUpdate, ctx);
    },
    renderCall(args, theme, context) {
      const pattern = truncate(args.pattern, 40);
      const path = formatRelativePath(args.path ?? ".", context.cwd);
      const target = `${pattern} in ${path}`;
      return renderCollapsedCall(context.lastComponent, theme, context, "find", target);
    },
    renderResult(result, options, theme, context) {
      const builtIn = getBuiltInTools(context.cwd).find;
      if (options.expanded || options.isPartial || context.isError) {
        return (
          builtIn.renderResult?.(result, options, theme, context) ??
          emptyCompactText(context.lastComponent)
        );
      }

      const textContent = getFirstTextBlock(result.content) ?? "";
      const fileCount = countNonEmptyLines(textContent);
      const details: FindToolDetails | undefined = result.details;
      let label = pluralize(fileCount, "file", "files");
      if (details?.resultLimitReached !== undefined) {
        label += " [limit]";
      }
      label += truncationSuffix(details?.truncation?.truncated === true);

      rememberCollapsedSummary(context, { status: "success", label });
      return emptyCompactText(context.lastComponent);
    },
  };

  pi.registerTool(tool);
}

function registerGrepTool(pi: ExtensionAPI, startupTools: BuiltInTools): void {
  const tool: GrepToolDefinition = {
    ...startupTools.grep,
    renderShell: "self",
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return getBuiltInTools(ctx.cwd).grep.execute(toolCallId, params, signal, onUpdate, ctx);
    },
    renderCall(args, theme, context) {
      const pattern = truncate(args.pattern, 40);
      const path = formatRelativePath(args.path ?? ".", context.cwd);
      let target = `/${pattern}/ in ${path}`;
      if (args.glob !== undefined) {
        target += ` (${truncate(args.glob, 24)})`;
      }
      return renderCollapsedCall(context.lastComponent, theme, context, "grep", target);
    },
    renderResult(result, options, theme, context) {
      const builtIn = getBuiltInTools(context.cwd).grep;
      if (options.expanded || options.isPartial || context.isError) {
        return (
          builtIn.renderResult?.(result, options, theme, context) ??
          emptyCompactText(context.lastComponent)
        );
      }

      const textContent = getFirstTextBlock(result.content) ?? "";
      const outputLineCount = countNonEmptyLines(textContent);
      const details: GrepToolDetails | undefined = result.details;
      const contextLines = typeof context.args.context === "number" ? context.args.context : 0;
      const labelBase =
        contextLines > 0
          ? pluralize(outputLineCount, "output line", "output lines")
          : pluralize(outputLineCount, "match", "matches");

      let label = labelBase;
      if (details?.matchLimitReached !== undefined) {
        label += " [limit]";
      }
      if (details?.linesTruncated === true) {
        label += " [line truncation]";
      }
      label += truncationSuffix(details?.truncation?.truncated === true);

      rememberCollapsedSummary(context, { status: "success", label });
      return emptyCompactText(context.lastComponent);
    },
  };

  pi.registerTool(tool);
}

function registerLsTool(pi: ExtensionAPI, startupTools: BuiltInTools): void {
  const tool: LsToolDefinition = {
    ...startupTools.ls,
    renderShell: "self",
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return getBuiltInTools(ctx.cwd).ls.execute(toolCallId, params, signal, onUpdate, ctx);
    },
    renderCall(args, theme, context) {
      return renderCollapsedCall(
        context.lastComponent,
        theme,
        context,
        "ls",
        formatRelativePath(args.path ?? ".", context.cwd),
      );
    },
    renderResult(result, options, theme, context) {
      const builtIn = getBuiltInTools(context.cwd).ls;
      if (options.expanded || options.isPartial || context.isError) {
        return (
          builtIn.renderResult?.(result, options, theme, context) ??
          emptyCompactText(context.lastComponent)
        );
      }

      const textContent = getFirstTextBlock(result.content) ?? "";
      const entryCount = countNonEmptyLines(textContent);
      const details: LsToolDetails | undefined = result.details;
      let label = pluralize(entryCount, "entry", "entries");
      if (details?.entryLimitReached !== undefined) {
        label += " [limit]";
      }
      label += truncationSuffix(details?.truncation?.truncated === true);

      rememberCollapsedSummary(context, { status: "success", label });
      return emptyCompactText(context.lastComponent);
    },
  };

  pi.registerTool(tool);
}

function registerWriteTool(pi: ExtensionAPI, startupTools: BuiltInTools): void {
  const tool: WriteToolDefinition = {
    ...startupTools.write,
    renderShell: "self",
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return getBuiltInTools(ctx.cwd).write.execute(toolCallId, params, signal, onUpdate, ctx);
    },
    renderCall(args, theme, context) {
      const path = formatRelativePath(args.path, context.cwd);
      const lineCount = countLines(args.content);
      const target = `${path} (${pluralize(lineCount, "line", "lines")})`;
      return renderCollapsedCall(context.lastComponent, theme, context, "write", target);
    },
    renderResult(result, options, theme, context) {
      const builtIn = getBuiltInTools(context.cwd).write;
      if (options.expanded || options.isPartial || context.isError) {
        return (
          builtIn.renderResult?.(result, options, theme, context) ??
          emptyCompactText(context.lastComponent)
        );
      }

      const textContent = getFirstTextBlock(result.content);
      if (textContent !== undefined && textContent.length > 0) {
        rememberCollapsedSummary(context, {
          status: "warning",
          label: truncate(firstLine(textContent), 60),
        });
        return emptyCompactText(context.lastComponent);
      }

      rememberCollapsedSummary(context, { status: "success", label: "written" });
      return emptyCompactText(context.lastComponent);
    },
  };

  pi.registerTool(tool);
}

export default function compactToolOutput(pi: ExtensionAPI): void {
  const startupTools = getBuiltInTools(process.cwd());

  registerFindTool(pi, startupTools);
  registerGrepTool(pi, startupTools);
  registerLsTool(pi, startupTools);
  registerWriteTool(pi, startupTools);
}
