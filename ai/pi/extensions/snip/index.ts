import { getErrorMessage } from "@accel-os/shared/guards";
/**
 * Route Pi bash calls through snip's native hook protocol.
 *
 * Snip decides whether a command is safe and useful to rewrite; this extension
 * only applies its replacement command. Pi remains the authorization owner.
 */
import { isToolCallEventType, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

import { runSnipHook } from "./hook.ts";

export type BashToolInput = {
  command: string;
  timeout?: number;
  cwd?: string;
};

type SnipHookRunner = typeof runSnipHook;

type SnipHookRewriteResult = {
  command?: string;
  error?: unknown;
};

export function createSnipHookSession(hook: SnipHookRunner = runSnipHook): {
  rewrite(input: BashToolInput, signal?: AbortSignal): Promise<SnipHookRewriteResult>;
} {
  let disabled = false;

  return {
    async rewrite(input, signal) {
      if (disabled) {
        return {};
      }
      try {
        const command = await hook(
          {
            tool_name: "bash",
            tool_input: input,
          },
          signal === undefined ? undefined : { signal },
        );
        return command === undefined ? {} : { command };
      } catch (error: unknown) {
        if (signal?.aborted === true) {
          return {};
        }

        disabled = true;
        return { error };
      }
    },
  };
}

export default function snipExtension(pi: ExtensionAPI): void {
  const session = createSnipHookSession();

  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType<"bash", BashToolInput>("bash", event)) {
      return;
    }

    const result = await session.rewrite(event.input, ctx.signal);
    if (result.command !== undefined) {
      event.input.command = result.command;
    }
    if (result.error !== undefined) {
      const message = getErrorMessage(result.error);
      ctx.ui.notify(`snip disabled for this session: ${message}`, "warning");
    }
  });
}
