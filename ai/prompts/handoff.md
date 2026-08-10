---
description: Serialize current agent state into a handoff for a fresh coding agent
---

Create a context-free handoff markdown document under `docs/` for a fresh agent.
Name it `docs/handoff-YYYY-MM-DD-<topic>.md`, using the current date and a
short kebab-case topic.

Focus on serializing the current agent state: important context, nuances,
decisions, assumptions, unresolved questions, plans, risks, and references needed
to continue the work without prior chat history.
If the user provided a topic or next-session focus, tailor the handoff around
that focus while preserving relevant current state.

Do not redo broad discovery. Only inspect files or git state when needed to
confirm exact paths, names, current changes, or validation results.
Do not duplicate content already captured in durable artifacts such as specs,
plans, ADRs, issues, commits, or diffs; reference them by path or URL instead.
Redact sensitive information such as API keys, tokens, passwords, secrets, and
personally identifiable information.
Prioritize current state over chronology: preserve active requirements, accepted
decisions, current file status, unresolved work, and next actions. Omit stale
drafts, superseded plans, irrelevant previous-task context, and exploratory dead
ends unless they explain a still-active constraint or rejected approach.

Include:

- Goal / requested outcome
- Current understanding of the problem
- Important context and nuances
- User-stated constraints, preferences, and rejected approaches
- Decisions made and rationale
- Assumptions and uncertainties
- Relevant files, symbols, docs, or commands
- Changed files and their current status
- Recap of work completed so far
- Remaining tasks / recommended next steps
- The next concrete action or command for the fresh agent
- Validation performed or still needed
- Unresolved errors, failing commands, or broken tests
- Known risks, blockers, or edge cases
- Open loops / decisions still needed

Avoid irrelevant history, generic repo summaries, and exhaustive dumps.
Do not invent missing context; mark unknowns explicitly.
Separate observed facts, inferences, and assumptions when it matters.
Prefer concise, durable, actionable notes.