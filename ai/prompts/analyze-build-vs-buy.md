---
description: Analyze any build-vs-buy decision
argument-hint: "<project, idea, component, or problem>"
---

Analyze this build-vs-buy decision:

$ARGUMENTS

Inspect the repository when relevant. Do not modify files.

Evaluate:

- what outcome is needed;
- what is differentiating versus commodity;
- build, buy, open-source, and defer/simplify options;
- integration effort versus implementation effort;
- initial cost, ongoing maintenance, operations, security, and opportunity cost;
- coupling, portability, lock-in, reversibility, and exit cost;
- whether a “simple internal version” is likely to remain simple;
- assumptions, unknowns, and evidence needed.

Return:

1. **Recommendation** — build, buy, adopt open source, defer, or run a time-boxed evaluation.
2. **Why** — the 3–5 dominant decision factors.
3. **Options** — concise comparison with major costs and risks.
4. **Boundary** — what should remain custom and what should be delegated.
5. **Unknowns** — decision-critical questions and the cheapest way to answer them.
6. **Reversal triggers** — conditions that should cause the decision to be revisited.

Rules:

- Separate verified facts from assumptions.
- Cite repository evidence with file paths when available.
- Use ranges instead of invented precision.
- Do not invent vendor pricing, capabilities, or compliance claims.
- Prefer reversible choices when evidence is weak.
- Be skeptical of both “we can build a simple version” and vendor feature lists.