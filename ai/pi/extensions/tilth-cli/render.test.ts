import assert from "node:assert/strict";
import test from "node:test";

import type { Theme } from "@earendil-works/pi-coding-agent";

import { renderTilthDiffCall, renderTilthReadCall } from "./render.ts";

const theme = {
  bg: (_color: string, text: string) => text,
  bold: (text: string) => text,
  fg: (_color: string, text: string) => text,
} as unknown as Theme;

interface RenderContext {
  args: Record<string, unknown>;
  state: object;
  lastComponent: undefined;
  invalidate: () => void;
  expanded: boolean;
  isError: boolean;
  executionStarted: boolean;
  cwd: string;
}

function renderContext(): RenderContext {
  return {
    args: {},
    state: {},
    lastComponent: undefined,
    invalidate(): void {},
    expanded: false,
    isError: false,
    executionStarted: false,
    cwd: "/repo",
  };
}

test("renderTilthReadCall identifies an external checkout scope", () => {
  const rendered = renderTilthReadCall(
    { path: "src/auth.ts", scope: "/tmp/untrusted/repo" },
    theme,
    renderContext(),
  );

  assert.equal(
    rendered.render(200).join("\n").trimEnd(),
    "  tilth_read src/auth.ts in ../tmp/untrusted/repo",
  );
});

test("renderTilthDiffCall displays patch mode before log mode", () => {
  const rendered = renderTilthDiffCall(
    { patch: "change.patch", log: "HEAD~2..HEAD" },
    theme,
    renderContext(),
  );

  assert.equal(rendered.render(200).join("\n").trimEnd(), "  tilth_diff patch change.patch");
});
