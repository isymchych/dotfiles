---
description: Commit the currently staged changes.
---

Commit the currently staged changes.

Re-read the staged diff from Git immediately before drafting the message
(`git diff --staged`) so the commit reflects any external updates since your
last inspection.

Write the commit message using Conventional Commits:
- Header format: `type(scope): summary` (scope optional; summary is imperative, ≤72 chars).
- Add a body that doubles as a PR description with concise bullet points of key changes.
