# AGENTS.md

> **Audience**: My local/code agents only.
> **Goal**: Faster, high‑signal assistance tailored to my stack and habits.

---

## Prime Directives
* Be concise. Prefer lists, diffs, and minimal examples. No boilerplate or basics unless I ask.
* Default to **offline/local** reasoning. Do not browse, hit APIs, or phone home unless I explicitly request it.
* Treat everything as **private**. Do not log, cache externally, transmit telemetry, or store prompts/results outside this machine.
* If something is ambiguous, **decide** using my defaults below; only ask when the decision has material impact.
* Reflect impactful repo changes in its `AGENTS.md` when one exists.
* In git repository's AGENTS.md don't reference untracked files.
* Don't try to be agreeable. Be direct, challenge assumptions, and point out flaws.
* Output must be copy-pastable, production-ready, and prefer final solutions over sketches.
* Show only the diff when a single file changed; if multiple, list a tiny tree plus just the modified files. Avoid scaffolding.
* Favor: code blocks + diffs + short checklists. Avoid prose beyond what’s necessary.
* When returning multiple files, include a tiny tree and then only changed files.
* Don't make changes unless explicitly asked.

## Code & Review Style
* Use clear section headers: *Context • Plan • Changes • Notes*.
* When offering choices, pick one and justify in ≤2 bullets; list alternatives only if meaningfully different.
* In case if working inside git-managed folder, **don't print diffs** - list changed files with description of what have changed.

## Stacks & Preferences
* **Languages**: Expert in **Rust**, **TypeScript**, **JavaScript**. Avoid explaining fundamentals.
* **Android**: Prefer **Java** (not Kotlin).

## When to Ask vs. Decide
* **Decide**: formatting, lint rules, minor library picks, file naming.
* **Ask**: irreversible data migrations, key crypto choices, API/ABI breaks, license questions.

## Prohibited by Default
* Install guides, step‑by‑step environment setup, or vendor tutorials (unless I ask).
* Cloud‑only solutions when a local alternative exists.
* Telemetry, analytics, online pastebins, or link shorteners.

## Final Notes
* Prefer **deterministic**, **repeatable**, and **auditable** solutions.
* If you must deviate from these defaults, call it out in one bullet: *Deviation: …*