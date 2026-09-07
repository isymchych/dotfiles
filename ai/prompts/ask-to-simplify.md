---
description: See if there are opportunities to simplify code
---

I'd like to know if we can simplify & clean up code: **$ARGUMENTS**.

Focus on:

- the smallest, simplest change that would solve the problem
- code that can be deleted
- standard-library or platform features that can replace custom code or dependencies
- abstractions that may not be earning their keep
- invariants that should be explicit or tested
- coupling points introduced or worsened
- module cohesion lowered by the change
- cognitive load for the next maintainer
- cleverness that can be avoided

I'm not asking you to review the code for correctness. Preserve behavior, and
do not recommend removing guards, tests, or constraints without understanding
the intent they protect.

Output:

List findings by impact, from high to low. Make each finding easy to scan:

- a short descriptive heading
- the relevant `file:line`
- why the current code is unnecessarily complex
- the concrete simplification
- brief evidence, such as caller, implementation, or usage counts, and any
  material tradeoff when relevant

Use these tags only when they make a finding clearer:

- `delete`: dead code, unused flexibility, or speculative functionality
- `stdlib`: custom code replaceable by the standard library
- `native`: a dependency or custom code replaceable by the platform
- `yagni`: an abstraction, option, or layer unsupported by current needs
- `shrink`: the same behavior expressed more directly
- `cohesion`: misplaced responsibility or a fragmented module
- `invariant`: a rule that can replace defensive states or branching

Do not optimize for line count; optimize for fewer concepts, states,
dependencies, and coupling points.

Do not manufacture findings. If none are worthwhile, say:
`No worthwhile simplifications found.`