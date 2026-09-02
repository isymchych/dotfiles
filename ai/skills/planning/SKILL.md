---
name: planning
description: Compact planning workflow for code work. Produces concise inline plans by default, with optional short `plans/<slug>.md` artifacts for larger, risky, or user-requested work.
disable-model-invocation: true
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
- Escalate design detail only when the change affects boundaries, ownership, data flow, public interfaces, invariants, migration risk, or long-term maintainability.
- For design-sensitive work, settle architecture and program design before implementation steps.

## Design Escalation

Use the smallest plan shape that makes the work safe to execute:

- Tiny or mechanical changes: use the default inline plan.
- Medium changes: include only the design facts needed to choose files, interfaces, and verification.
- Boundary, refactor, or risky changes: include explicit architecture and program design before execution steps.

When architecture detail is needed, cover:

- ownership and module boundaries;
- dependency direction and data flow;
- affected contracts, interfaces, or schemas;
- the canonical owner for rules, parsing, normalization, and invariants.

When program design detail is needed, cover:

- expected files or modules to touch;
- key functions, types, or data structures;
- call flow through the changed code;
- validation boundaries and test seams;
- compatibility or migration decisions when relevant.

## Inline Plan Shape

Default to:

1. `Findings` - only facts that affect the plan.
2. `Plan` - concrete steps, as many as needed; combine tiny mechanical actions and split material decision/checkpoint boundaries.
3. `Questions` - only unresolved blockers; omit when none.

Add `Risks`, `Alternatives`, `Assumptions`, or `Verification` only when material.

For design-sensitive work, also add `Architecture` and/or `Program Design` sections when those decisions must be settled before implementation.

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

## Architecture

- Boundaries / ownership:
- Contracts / data flow:
- Invariant owner:

## Program Design

- Files / modules:
- Key functions / types:
- Call flow:
- Validation / test seams:

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
- Material design decisions are resolved before implementation steps, not deferred to execution.
- Plans identify the canonical owner for rules, parsing, normalization, and invariants when those decisions are in scope.
- Avoid vague discovery steps such as "inspect and figure it out" when repo inspection can resolve the answer before planning.
- Alternatives are real choices, not forced option theater.
- The plan stays smaller than the work it enables.