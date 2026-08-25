import assert from "node:assert/strict";
import test from "node:test";

import { parseTouchpadArgs, parseTouchpadEnabled } from "./mb-touchpad.ts";

test("parseTouchpadArgs accepts the existing Sway command", () => {
  assert.deepEqual(parseTouchpadArgs(["-n", "toggle"]), {
    help: false,
    notify: true,
    action: "toggle",
  });
});

test("parseTouchpadEnabled accepts provider-owned extra fields", () => {
  assert.equal(
    parseTouchpadEnabled(
      JSON.stringify([
        { type: "keyboard", identifier: "keyboard" },
        {
          type: "touchpad",
          identifier: "touchpad",
          libinput: { send_events: "enabled", tap: "enabled" },
        },
      ]),
    ),
    true,
  );
});

test("parseTouchpadEnabled reports disabled state", () => {
  assert.equal(
    parseTouchpadEnabled(
      JSON.stringify([{ type: "touchpad", libinput: { send_events: "disabled" } }]),
    ),
    false,
  );
});

test("parseTouchpadEnabled treats non-enabled provider states as disabled", () => {
  assert.equal(
    parseTouchpadEnabled(
      JSON.stringify([
        { type: "touchpad", libinput: { send_events: "disabled_on_external_mouse" } },
      ]),
    ),
    false,
  );
});

test("parseTouchpadEnabled rejects missing touchpads", () => {
  assert.throws(
    () => parseTouchpadEnabled(JSON.stringify([{ type: "keyboard" }])),
    /Could not find a touchpad/u,
  );
});
