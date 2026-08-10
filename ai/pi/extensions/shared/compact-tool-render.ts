import { homedir } from "node:os";
import { isAbsolute, relative, resolve } from "node:path";

import type { Theme } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

export type CompactSummaryStatus = "success" | "warning";

interface CompactSummary {
  status: CompactSummaryStatus;
  label: string;
}

interface CompactRenderState {
  collapsedSummary?: CompactSummary;
}

export interface CompactRenderContext {
  state: unknown;
  lastComponent: unknown;
  invalidate: () => void;
  expanded: boolean;
  isError: boolean;
  executionStarted: boolean;
}

export function setCompactText(lastComponent: unknown, content: string): Text {
  const text = lastComponent instanceof Text ? lastComponent : new Text("", 0, 0);
  text.setText(content);
  return text;
}

function getCompactState(state: unknown): CompactRenderState {
  if (typeof state !== "object" || state === null) {
    throw new Error("compact tool rendering expected an object render state");
  }
  return state;
}

export function rememberCollapsedSummary(
  context: CompactRenderContext,
  summary: CompactSummary,
): void {
  const state = getCompactState(context.state);
  const previous = state.collapsedSummary;
  if (previous?.status === summary.status && previous.label === summary.label) {
    return;
  }
  state.collapsedSummary = summary;
  context.invalidate();
}

export function emptyCompactText(lastComponent: unknown): Text {
  return setCompactText(lastComponent, "");
}

function expandHome(path: string): string {
  if (path === "~") {
    return homedir();
  }
  if (path.startsWith("~/")) {
    return resolve(homedir(), path.slice(2));
  }
  return path;
}

export function formatRelativePath(path: string, cwd: string): string {
  const expanded = expandHome(path);
  const absolutePath = isAbsolute(expanded) ? expanded : resolve(cwd, expanded);
  const displayPath = relative(cwd, absolutePath);
  return displayPath.length === 0 ? "." : displayPath;
}

export function pluralize(count: number, singular: string, plural: string): string {
  return `${count} ${count === 1 ? singular : plural}`;
}

export function renderCollapsedCall(
  lastComponent: unknown,
  theme: Theme,
  context: CompactRenderContext,
  toolLabel: string,
  target: string,
): Text {
  const state = getCompactState(context.state);
  let text = "  " + theme.fg("toolTitle", theme.bold(toolLabel));
  if (target.length > 0) {
    text += ` ${theme.fg("accent", target)}`;
  }

  if (context.isError) {
    text = theme.bg("toolErrorBg", ` ${text} `);
  } else if (!context.expanded && state.collapsedSummary !== undefined) {
    text += theme.fg("muted", " -> ");
    text += theme.fg(state.collapsedSummary.status, state.collapsedSummary.label);
  } else if (!context.expanded && context.executionStarted) {
    text += theme.fg("warning", " ...");
  }

  return setCompactText(lastComponent, text);
}
