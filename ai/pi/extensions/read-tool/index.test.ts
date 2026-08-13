import assert from "node:assert/strict";
import test from "node:test";

import type { Theme } from "@earendil-works/pi-coding-agent";

import readToolExtension, { renderExpandedText } from "./index.ts";

const theme = {
  fg(_color: string, text: string): string {
    return text;
  },
  bg(_color: string, text: string): string {
    return text;
  },
  bold(text: string): string {
    return text;
  },
} as Theme;

test("renders expanded output without terminal control sequences", () => {
  const rendered = renderExpandedText(
    [
      { type: "text", text: "plain \u001b[31mred\u001b[0m" },
      { type: "image" },
      { type: "text", text: "\u001b]8;;https://example.test\u0007link\u001b]8;;\u0007" },
      { type: "text", text: "\u001b_cursor-marker\u001b\\" },
    ],
    theme,
  );

  assert.equal(rendered, "\nplain red\nlink\n");
  assert.equal(rendered.includes("\u001b"), false);
});

test("renders every multi-target read result in the collapsed summary", async () => {
  let toolDefinition:
    | {
        renderCall: (
          args: { targets: Array<{ path: string }>; recursive?: boolean },
          theme: Theme,
          context: {
            args: unknown;
            lastComponent: unknown;
            state: object;
            invalidate: () => void;
            expanded: boolean;
            isError: boolean;
            executionStarted: boolean;
          },
        ) => { render: (width: number) => string[] };
        renderResult: (
          result: {
            content: [];
            details: {
              targets: Array<{
                path: string;
                kind: "file" | "directory" | "image" | "error";
                lineCount?: number;
                entryCount?: number;
              }>;
            };
          },
          options: { expanded: boolean; isPartial: boolean },
          theme: Theme,
          context: {
            args: unknown;
            lastComponent: unknown;
            state: object;
            invalidate: () => void;
            isError: boolean;
          },
        ) => unknown;
      }
    | undefined;
  const pi = {
    registerTool(tool: typeof toolDefinition): void {
      toolDefinition = tool;
    },
  };

  readToolExtension(pi as never);
  assert.ok(toolDefinition);

  const renderState = {};
  const args = {
    targets: [{ path: "a.ts" }, { path: "src" }, { path: "logo.png" }, { path: "missing.ts" }],
  };
  const context = {
    args,
    lastComponent: undefined,
    state: renderState,
    invalidate(): void {},
    expanded: false,
    isError: false,
    executionStarted: false,
  };
  const header = toolDefinition.renderCall(args, theme, context);
  toolDefinition.renderResult(
    {
      content: [],
      details: {
        targets: [
          { path: "a.ts", kind: "file", lineCount: 80 },
          { path: "src", kind: "directory", entryCount: 4 },
          { path: "logo.png", kind: "image" },
          { path: "missing.ts", kind: "error" },
        ],
      },
    },
    { expanded: false, isPartial: false },
    theme,
    context,
  );

  assert.deepEqual(
    header
      .render(100)
      .slice(1, -1)
      .map((line) => line.trimEnd()),
    [
      " read 4 targets",
      " a.ts (80L)",
      " src (4 entries)",
      " logo.png (image)",
      " missing.ts (failed)",
    ],
  );
});
