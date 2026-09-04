# Tilth MCP Cache and Pi Session Trees

## Status

Proposed implementation guidance. This document records the preferred way to keep Tilth on `pi-mcp-adapter` while preventing Tilth's process-local output deduplication from leaking across Pi conversation branches.

The current staged work replaces Tilth MCP with one-shot Tilth CLI tools under `ai/pi/extensions/tilth-cli/`. Do not implement this proposal by layering MCP Tilth underneath those tools. First choose one canonical Tilth transport and remove or revert the conflicting staged transport changes.

## Problem

Pi sessions are trees. `/tree` can move the active leaf to a point whose model context does not contain tool output produced on the abandoned branch. Compaction can similarly remove old tool output from the active model context.

Tilth MCP keeps a process-local `Session.expanded` map. Search and grok use it to replace a previously expanded definition with `[shown earlier]`. The map is keyed by source path and line, with file mtime used to invalidate entries after normal file changes.

This is correct for a linear conversation but not for Pi tree navigation:

1. branch A expands a definition;
2. Tilth records that expansion in its MCP process;
3. `/tree` moves Pi to a leaf before, or outside, branch A;
4. branch A's tool result is absent from the active model context;
5. another Tilth search can return `[shown earlier]` because the MCP process still remembers branch A.

The failure is a state-ownership mismatch: "the model has seen this output" is branch-local context state, but Tilth stores it as process-lifetime server state.

## Decision

When Tilth is hosted by `pi-mcp-adapter`, reconnect only the `tilth` MCP server after a successful Pi tree transition. Reconnection replaces the Tilth stdio process and therefore clears its process-local expansion history.

Use the adapter's documented command:

```text
/mcp reconnect tilth
```

Do not kill processes, inspect PIDs, poll Git, restart all MCP servers, or patch private adapter modules. The reconnect command is the adapter-owned public lifecycle boundary.

Compaction handling may use the same mechanism when Pi is idle. Automatic and overflow-recovery compaction require special care because they can occur inside an active agent run; see [Compaction limitations](#compaction-limitations).

## Why this approach

- It uses public Pi and `pi-mcp-adapter` surfaces.
- It resets the exact server whose process owns the stale state.
- It avoids changes to Tilth or `pi-mcp-adapter`.
- It preserves MCP tool registration and adapter configuration.
- It is deterministic for `/tree`, unlike idle timeouts.
- Tilth startup is small enough that an occasional branch-transition restart is an acceptable cost.

The cost is coarse invalidation: reconnecting also discards useful process-local caches, not only the expanded-definition map. A future first-class reset call would be more efficient, but the additional integration is not currently justified.

## Relevant public contracts

### Pi

Pi emits:

- `session_tree` after successful `/tree` navigation, with `oldLeafId` and `newLeafId`;
- `session_compact` after successful compaction;
- no success event when tree navigation is cancelled or compaction fails.

`pi.sendUserMessage()` can dispatch extension commands when called with `expandPromptTemplates: true`. Pi does not expose a general API for one extension to invoke another extension's registered command directly.

### pi-mcp-adapter

`pi-mcp-adapter` documents:

- `/mcp reconnect <server>`: connect or reconnect one server;
- `mcp({ connect: "tilth" })`: model-facing connect/reconnect behavior;
- lifecycle modes and idle disconnection, which are not synchronized with Pi tree navigation.

For a connected stdio server, reconnecting closes and replaces the connection/process. This is what clears Tilth's process-local `Session`.

### Tilth

Tilth has an internal `tilth_session` reset action, but it is not advertised in the MCP `tools/list` response. A separate Tilth process cannot reset the state of the process owned by the adapter. Do not launch another MCP process merely to call reset.

Tilth's mtime checks already handle ordinary working-tree edits and Git checkouts. Git HEAD or index changes alone do not mean that source previously shown to the model became stale. Do not add Git watchers as part of this fix.

## Proposed extension design

Keep the integration small and lifecycle-only. A suitable location is:

```text
ai/pi/extensions/tilth-mcp-lifecycle/index.ts
```

Add high-level TSDoc explaining that the extension reconciles Tilth's linear MCP session cache with Pi's conversation-tree lifecycle.

The tree hook should:

1. listen to `session_tree`, not `session_before_tree`;
2. ignore events where `oldLeafId === newLeafId`;
3. defer command dispatch until tree navigation has returned, avoiding nested command execution inside the event emitter;
4. coalesce duplicate reconnect requests;
5. dispatch `/mcp reconnect tilth` with command expansion enabled;
6. avoid adding a normal user/agent turn.

Starting point:

```ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Reconnect Tilth MCP after Pi leaves a conversation-tree leaf so Tilth cannot
 * suppress source whose original expansion exists only on an abandoned branch.
 */
export default function tilthMcpLifecycle(pi: ExtensionAPI): void {
  let reconnectScheduled = false;

  function scheduleReconnect(): void {
    if (reconnectScheduled) return;
    reconnectScheduled = true;

    setTimeout(() => {
      reconnectScheduled = false;
      pi.sendUserMessage("/mcp reconnect tilth", {
        expandPromptTemplates: true,
      });
    }, 0);
  }

  pi.on("session_tree", (event) => {
    if (event.oldLeafId !== event.newLeafId) {
      scheduleReconnect();
    }
  });
}
```

This is a design sketch, not verified production code. Confirm the command-dispatch and transcript behavior against the installed Pi and adapter versions before adopting it.

## Compaction limitations

Resetting after successful compaction is semantically desirable because a compacted-away Tilth result may no longer be in model context. However, `session_compact` can fire during threshold or overflow recovery while an agent run is active.

`pi.sendUserMessage()` requires an explicit delivery mode while streaming. Queuing `/mcp reconnect tilth` as `steer` or `followUp` may execute too late to protect the immediate post-compaction retry, and it may perturb the active run. Therefore:

- the initial implementation should solve `/tree` first;
- it may reconnect after manual/idle compaction when `ctx.isIdle()` is true;
- it must not claim automatic-compaction correctness unless a test proves the reconnect runs before the retry's next Tilth call;
- if immediate automatic-compaction reset becomes required, prefer a first-class adapter event-bus reconnect API over command injection.

A conservative follow-up can record a pending reconnect on `session_compact` and perform it at `agent_settled`. That prevents stale state in later user turns but does not protect tool calls made during the automatic retry itself.

## Session replacement behavior

`/new`, `/resume`, `/fork`, and `/clone` replace the Pi session runtime. Pi emits `session_shutdown`, reloads/rebinds extensions, and starts a fresh session runtime. The adapter should close session-scoped MCP connections during shutdown.

Do not add an unconditional `session_start` reconnect unless verification shows the adapter preserves the Tilth process across session replacement. Unnecessary startup reconnects add latency and may race lazy server initialization.

`/reload` also replaces the extension runtime. Treat adapter shutdown/reload as the owner of connection cleanup.

## Configuration implications

If this design is selected instead of the staged one-shot CLI design:

1. restore the `tilth` server in `ai/pi/mcp.json`;
2. keep its server name exactly `tilth`, because the lifecycle command depends on that stable identifier;
3. retain the intended `directTools`, `toolPrefix`, lifecycle, PATH, and resource settings;
4. ensure `pi-mcp-adapter` is loaded for runs where Tilth MCP tools are expected;
5. add `tilth-mcp-lifecycle` to `defaultExtensionNames` in `ai/pi/runtime/pi-launcher.ts`;
6. remove the one-shot `tilth-cli` extension from the default list and tool allowlist unless an explicit fallback mode is intentionally designed;
7. update launcher help and tests so they describe the selected transport accurately.

Do not keep two implementations registering the same `tilth_*` tool names. Registration order would determine behavior and make debugging ambiguous.

## Alternatives rejected

### Tiny adapter idle timeout

Idle shutdown is eventual and checked on a timer. It is not tied to `/tree`, so the next Tilth call may occur before disconnection.

### Manual reconnect

`/mcp reconnect tilth` is a useful diagnostic and fallback, but relying on the user to remember it does not enforce correctness.

### Process killing

PID discovery and `pkill` couple the extension to process details, can target the wrong process, and bypass adapter cleanup and status synchronization.

### Separate reset process

Tilth state is process-local. Starting another Tilth server and resetting it has no effect on the adapter-owned server.

### Git-state watchers

The bug is conversation-context invalidation, not primarily source invalidation. Tilth already checks file mtime. Git polling adds races and unrelated resets without addressing `/tree` directly.

### Branch-state snapshot and restore

Perfect branch-local deduplication would snapshot Tilth's expanded set per Pi leaf and restore it when navigating. Tilth exposes neither export nor import of that state, and Pi's adapter exposes no same-connection arbitrary-call API for extensions. The protocol and persistence complexity is not warranted unless reconnect cost becomes material.

### Patch Tilth or pi-mcp-adapter immediately

A Tilth dedup epoch/context ID or an adapter event-bus reconnect request would be cleaner long-term interfaces. The documented reconnect command is sufficient for the primary `/tree` failure, so upstream patches should be considered only if command dispatch proves unreliable or automatic-compaction correctness becomes required.

## Verification plan

Implement with targeted tests and one live integration check.

### Extension tests

- `session_tree` with different leaf IDs schedules exactly one reconnect.
- identical old/new leaf IDs schedule nothing.
- repeated events before the deferred callback are coalesced.
- dispatched text is exactly `/mcp reconnect tilth`.
- `expandPromptTemplates` is `true`.
- shutdown or reload does not leave a callback using stale extension state; add cancellation if the test exposes this race.

### Live Pi check

1. Start Pi with `pi-mcp-adapter`, Tilth MCP, and the lifecycle extension.
2. Search for a sufficiently large definition and confirm its body is expanded.
3. Use `/tree` to navigate to a point before that tool result.
4. Confirm the adapter reconnects only the `tilth` server.
5. Search for the same definition and confirm the full body is shown rather than `[shown earlier]`.
6. Confirm the reconnect command does not remain as a normal user message or trigger an unintended model turn.
7. Cancel `/tree` and confirm no reconnect occurs.
8. Confirm Chrome DevTools and other MCP servers remain connected.
9. Repeat after returning to the original branch; showing the body again is acceptable conservative behavior.

### Compaction check before enabling its hook

Test manual, threshold, and overflow compaction separately. Record whether the reconnect executes before any automatic retry and whether it alters queued messages. Enable a `session_compact` hook only for the modes proven safe.

## Decision boundary for future changes

Keep the reconnect-command approach while all of the following hold:

- `/tree` reconnect dispatch is reliable and invisible to conversation context;
- Tilth restart latency remains negligible in normal use;
- coarse cache invalidation does not create material performance problems;
- automatic-compaction gaps are acceptable or absent in observed workflows.

Request or implement a first-class adapter reconnect event when command injection becomes unreliable or automatic retries require synchronous reset. Request a Tilth dedup epoch or branch-aware state API only when preserving cache state across branch returns has measurable value.

## Evidence locations

- Pi extension lifecycle and command dispatch: installed `@earendil-works/pi-coding-agent/docs/extensions.md`.
- Adapter reconnect command and lifecycle behavior: installed `pi-mcp-adapter/README.md`, `proxy-modes.ts`, and `lifecycle.ts`.
- Tilth expansion state: upstream `src/session.rs`, search formatting, and MCP dispatch for `tilth_session`.
- Current transport selection and extension loading: `ai/pi/mcp.json`, `ai/pi/ai.ts`, and `ai/pi/runtime/pi-launcher.ts`.
