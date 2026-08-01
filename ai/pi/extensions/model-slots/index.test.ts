import assert from "node:assert/strict";
import test from "node:test";

import { scopedModelAtSlot } from "./index.ts";

test("scopedModelAtSlot uses one-based slot numbers", () => {
  const models = ["luna", "gpt-5.5", "terra"];

  assert.equal(scopedModelAtSlot(models, 1), "luna");
  assert.equal(scopedModelAtSlot(models, 3), "terra");
});

test("scopedModelAtSlot rejects unavailable and invalid slots", () => {
  const models = ["luna"];

  assert.equal(scopedModelAtSlot(models, 0), undefined);
  assert.equal(scopedModelAtSlot(models, 1.5), undefined);
  assert.equal(scopedModelAtSlot(models, 2), undefined);
});
