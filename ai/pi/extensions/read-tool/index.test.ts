import assert from "node:assert/strict";
import test from "node:test";

import type { Theme } from "@earendil-works/pi-coding-agent";

import { renderExpandedText } from "./index.ts";

const theme = {
  fg(_color: string, text: string): string {
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
