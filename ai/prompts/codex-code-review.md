---
description: Review a diff, file, or pasted code for high-impact bugs
argument-hint: "[diff|commit|file|snippet]"
---

Review this code target: **$ARGUMENTS**.

The target may be a git diff, a commit or range, a file path, or pasted code.

First classify the target:

- **Diff target**: git refs, commit ranges, or flags such as `--staged`, `--unstaged`, and `--working-tree`.
- **File target**: one or more existing file paths.
- **Snippet target**: pasted code or an instruction containing code.

If the target is ambiguous, prefer an existing file path over a git ref. If it is still ambiguous, ask one concise clarification question before reviewing.

For diff targets, resolve `$ARGUMENTS` into the exact diff to review. Review only changes in that diff. Do not report pre-existing issues outside it.

For file and snippet targets, review only the provided code. Do not assume missing surrounding context. Do not report missing imports, callers, tests, or integration behavior unless the provided code makes the bug clear.

For PR target don't try to run/lint/test it.

Accepted examples:

- `HEAD` — last commit
- `HEAD~1..HEAD` — explicit commit range
- `main...HEAD` — current branch vs local main
- `origin/main...HEAD` — current branch vs remote main
- `--staged` — staged changes only
- `--unstaged` — unstaged changes only
- `--working-tree` — all uncommitted changes
- `<commit>` — one specific commit
- `src/example.ts` — current file contents
- pasted function or class — provided code only

Review the target and report only clear, actionable bugs.

Prefer more specific instructions over these defaults.

Flag an issue only when it is:

- a real bug with meaningful impact
- introduced by this patch when reviewing a diff
- present in the provided code when reviewing a file or snippet
- discrete and fixable
- likely something the author would want to fix
- supported by a concrete affected case, not speculation
- not just an intentional behavior change
- not dependent on guessing hidden intent or assumptions

Ignore trivial style unless it harms clarity or violates stated standards.

Return every qualifying issue. If none clearly qualify, return none.

For each finding:

- keep it to one issue
- explain briefly why it is a bug
- describe when it happens
- match the stated severity to the actual impact
- use a neutral, direct tone

Keep references as narrow as possible. Prefer the smallest code range that makes the issue clear.

Priority guide:

- P0: blocking / must fix immediately
- P1: urgent
- P2: normal
- P3: low priority

Consider the target correct if it has no clear breaking or blocking issues under the selected review mode. Ignore nits like style, formatting, typos, and docs in that judgment.