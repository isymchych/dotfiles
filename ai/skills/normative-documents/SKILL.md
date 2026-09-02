---
name: normative-documents
description: Create or edit normative documents such as specifications, policies, plans, ADRs, AGENTS.md files, and other guidance that defines requirements or decision rules.
---

# Normative Documents

Treat normative documents as sources of truth for required or recommended
behavior, constraints, and decision rules.

- Treat requirement-level edits as behavior changes.
- Write stable guidance that remains useful after the current context is
  forgotten.
- Prefer durable decision rules over implementation chronology, change
  narration, ticket context, temporary workarounds, or actor/time-specific
  notes.
- Prefer domain rules over storage or implementation details.
- Keep guidance self-contained, concise, and non-duplicative.
- Keep negative requirements only when the prohibited absence or behavior is
  itself an invariant.
- Keep the edited scope and directly affected guidance internally consistent.
- Check the directly affected scope for contradictions, missing decision
  guidance, and duplicated rules. Do not expand into a comprehensive review
  unless requested.
- Reconcile materially affected requirements in the same document or directly
  related governing documents. Report blockers when reconciliation is outside
  the authorized scope.
- Use positive phrasing where practical.
- For each edited normative section, report requirement changes as `preserved`,
  `modified`, `removed`, or `added`.
- Ask before removing requirements beyond the user's explicit request.