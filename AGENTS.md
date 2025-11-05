# Repository Guidelines

## Project Structure & Module Organization
- Follow chezmoi naming: `dot_*` for dotfiles, `dot_config/<tool>` for config trees, `darwin_*/` or other OS prefixes for platform-specific variants, and `run_once_*` for provisioning scripts.
- Keep per-tool docs close to their config (for example, `docs/linux/README.md`, `docs/mac/README.md`) and update them when behaviour changes.
- New files should land directly under the chezmoi layout they deploy to; avoid recreating legacy Stow packages.
- Point any launcher bindings at the `bin/executable_xterm` shim so the actual terminal choice stays centralized.
- The `bin/executable_xterm` shim launches `wezterm`; pass `-e` yourself only when you need non-default command execution semantics.

## Build, Test, and Development Commands
- `chezmoi diff` — review the rendered changes before applying.
- `chezmoi apply --dry-run` — double-check for surprises without touching the filesystem.
- `chezmoi apply` — materialize the source state after you have inspected the diff.
- `rg "<pattern>"` — preferred search for auditing changes across config files.

## Coding Style & Naming Conventions
- Preserve existing whitespace: two spaces for Lua and shell indentation, four spaces for nested TOML arrays, and no tabs.
- Keep option tables and environment blocks alphabetized where practical (`alacritty.toml`, `zsh/.zshrc`) to simplify diff reviews.
- Preserve lower-case, hyphen-free directory names inside `dot_config` unless upstream dictates otherwise.
- Document non-obvious tweaks with inline comments referencing the source or rationale; avoid redundant narration.
- During refactors, keep existing comments when they remain accurate; revise or drop them only when the behavior they describe changes.

## Commit & Pull Request Guidelines
- Follow the short, imperative message style already in history (`fix alacritty theme`, `bump configs`); scope each commit to one package.
- Reference affected modules in the subject or body (`alacritty`, `neovim`, `zsh`) so chezmoi users can gauge impact quickly.
- PRs must include: summary of intent, list of touched packages, manual verification notes, and any platform caveats.

## Security & Configuration Tips
- Never commit credentials or machine-specific secrets; rely on local excludes or `~/.config` overlays kept outside git.
- Use `chezmoi apply --dry-run` before first-time deployment on a host to prevent overwriting existing dotfiles; resolve conflicts explicitly.
- Update `.gitignore` when introducing generated artifacts (caches, compiled outputs) to keep the worktree clean.
- Coordinate environment-wide binaries via `tools/README.md`; note version pins when behavior depends on a specific release.
