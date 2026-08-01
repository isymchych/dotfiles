/**
 * Model Slots Extension
 *
 * Selects the nth scoped model directly with Alt+1 through Alt+9. The
 * enabledModels setting remains the single source of truth for slot order.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const SLOT_SHORTCUTS = [
  "alt+1",
  "alt+2",
  "alt+3",
  "alt+4",
  "alt+5",
  "alt+6",
  "alt+7",
  "alt+8",
  "alt+9",
] as const;

export function scopedModelAtSlot<T>(scopedModels: readonly T[], slot: number): T | undefined {
  if (!Number.isInteger(slot) || slot < 1) {
    return undefined;
  }

  return scopedModels[slot - 1];
}

async function selectModelSlot(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  slot: number,
): Promise<void> {
  if (!ctx.isIdle()) {
    ctx.ui.notify("Model slots are available when Pi is idle.", "warning");
    return;
  }

  const scopedModel = scopedModelAtSlot(ctx.scopedModels, slot);
  if (scopedModel === undefined) {
    ctx.ui.notify(`No model assigned to Alt+${slot}.`, "warning");
    return;
  }

  const success = await pi.setModel(scopedModel.model);
  if (!success) {
    ctx.ui.notify(`No API key for ${scopedModel.model.provider}/${scopedModel.model.id}.`, "error");
    return;
  }

  if (scopedModel.thinkingLevel !== undefined) {
    pi.setThinkingLevel(scopedModel.thinkingLevel);
  }

  ctx.ui.notify(`Alt+${slot}: ${scopedModel.model.provider}/${scopedModel.model.id}`, "info");
}

export default function modelSlotsExtension(pi: ExtensionAPI): void {
  SLOT_SHORTCUTS.forEach((shortcut, index) => {
    const slot = index + 1;
    pi.registerShortcut(shortcut, {
      description: `Select scoped model ${slot}`,
      handler: async (ctx) => {
        await selectModelSlot(pi, ctx, slot);
      },
    });
  });
}
