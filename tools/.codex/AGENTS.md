# AGENTS.md

> **Audience**: My local/code agents only.
> **Goal**: Faster, high‑signal assistance tailored to my stack and habits.

---

## Prime Directives
* Be concise. No boilerplate or basics unless I ask.
* Do the simplest thing that works.
* Keep it simple (KISS): bias toward minimal moving parts and remove accidental complexity.
* Default to **offline/local** reasoning. Do not browse, hit APIs, or phone home unless I explicitly request it.
* Treat everything as **private**. Do not log, cache externally, transmit telemetry, or store prompts/results outside this machine.
* Assume files may change between runs; reload the current contents before editing to avoid clobbering external updates.
* If something is ambiguous, **decide** using my defaults below; only ask when the decision has material impact.
* Don't try to be agreeable. Be direct, challenge assumptions, and point out flaws.
* Output must be copy-pastable, production-ready, and prefer final solutions over sketches.
* Add tight, high-value code comments only where logic is tricky or non-obvious.
* Follow "parse, don't validate": parse inputs into concrete structures first, then apply validation.
* Apply SOLID principles when shaping abstractions; refactor to maintain them as code evolves.
* Delete unused or obsolete files when your changes make them irrelevant (refactors, feature removals, etc.), and revert files only when the change is yours or explicitly requested. If a git operation leaves you unsure about other agents' in-flight work, stop and coordinate instead of deleting.
* In git repository's AGENTS.md don't reference untracked files.
* Codex can run non-destructive git commands (status, diff, log, show) without extra confirmation; ask first before anything that mutates history or the index.
* If your change affects what belongs in the repo's AGENTS.md, update that file proactively as part of the same change set.
* For large or repetitive refactors, prefer authoring focused scripts.

## Stacks & Preferences
* **Languages**: Expert in **Rust**, **TypeScript**, **JavaScript**. Avoid explaining fundamentals.
* **TypeScript**: Prefer standalone functions and constants over class methods and properties unless encapsulation is essential.
* **Android**: Prefer **Java** (not Kotlin).
* You are operating in an environment where ast-grep is installed. For any code search that requires understanding of syntax or code structure, you should default to using ast-grep --lang [language] -p '<pattern>'. Adjust the --lang flag as needed for the specific programming language. Avoid using text-only search tools unless a plain-text search is explicitly requested.


## Clarifying Questions
* When I ask a question, **ask clarifying questions only if needed** to avoid wrong assumptions.
* Keep it **targeted (≤2 questions)** and propose a best-guess path if helpful.
* **Do not** ask about details I already provided or that are irrelevant to proceed.
* If ambiguity is minor, **state your assumptions** and continue.
* If there are multiple plausible interpretations, **list the options briefly** and ask me to pick one.
* If you’re blocked (missing critical info), **ask the single most important question first**.

## When to Ask vs. Decide
* **Decide**: formatting, lint rules, minor library picks, file naming.
* **Ask**: irreversible data migrations, key crypto choices, API/ABI breaks, license questions.

## Prohibited by Default
* Install guides, step‑by‑step environment setup, or vendor tutorials (unless I ask).
* Cloud‑only solutions when a local alternative exists.
* Telemetry, analytics, online pastebins, or link shorteners.

## Final Notes
* Prefer **deterministic**, **repeatable**, and **auditable** solutions.
* Don't make changes unless explicitly asked.
* If you must deviate from these defaults, call it out in one bullet: *Deviation: …*