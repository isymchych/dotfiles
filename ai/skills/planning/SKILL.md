---
name: planning
description: Compact planning workflow for code work. Use when the user asks for a plan, or explicitly invokes planning. Produces concise inline plans by default, with optional short `plans/<slug>.md` artifacts for larger, risky, or user-requested work.
---

# Planning

Use planning to turn intent into an execution-ready path without ceremony.

## Core Behavior

- Inspect the relevant code, configs, tests, and docs before proposing implementation steps.
- Prefer a concise inline plan.
- Write `plans/<slug>.md` only when the user asks, the work needs a durable handoff, or the change is large/risky enough that an artifact materially helps.
- Ask only blocking questions that repo/environment inspection cannot answer.
- Recommend one path by default; discuss alternatives only when the choice materially affects architecture, scope, risk, or verification.
- Keep the plan concrete enough that implementation can start without material design decisions.

## Inline Plan Shape

Default to:

1. `Findings` - only facts that affect the plan.
2. `Plan` - concrete steps, as many as needed; combine tiny mechanical actions and split material decision/checkpoint boundaries.
3. `Questions` - only unresolved blockers; omit when none.

Add `Risks`, `Alternatives`, `Assumptions`, or `Verification` only when material.

## Written Plan Shape

When a plan file is useful, keep it short and canonical:

```md
# <Title>

## Context

- User goal:
- Constraints:
- Non-goals:

## Findings

- <path or area> - <fact that affects the plan>

## Decisions

- Chosen approach:
- Alternatives considered, if material:
- Assumptions, if any:

## Steps

- [ ] <execution-ready step with expected files/areas and completion checkpoint>
- [ ] <execution-ready step>

## Verification

- Acceptance checks:
- Commands/manual checks:

## Risks / Rollback

- Risk:
- Mitigation:
- Rollback:
```

Omit empty optional sections when they add no value.

## Quality Bar

- Steps name expected files, interfaces, or boundaries when useful.
- Verification is scoped and runnable where possible.
- Material uncertainty is surfaced before execution, not hidden inside a step.
- Alternatives are real choices, not forced option theater.
- The plan stays smaller than the work it enables.