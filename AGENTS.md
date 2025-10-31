# Repository Guidelines

## Project Structure & Module Organization
- Root directories mirror GNU Stow packages; symlinkable config lives under the same paths you expect in `$HOME` (e.g., `alacritty/.config/alacritty`, `neovim/.config/nvim`, `zsh/.zshrc`).
- Platform overrides belong in `linux/` and `mac/`; isolate OS-specific tweaks there to avoid cross-platform regressions.
- Keep per-tool docs close to their package (`emacs/README.md`, `tools/README.md`); update them alongside config changes.
- When introducing a new package, name the directory after the target application and recreate the exact directory hierarchy that Stow should deploy.
- Point any launcher bindings at the `linux/bin/xterm` shim so the actual terminal choice stays centralized.
- The `linux/bin/xterm` shim currently launches `ghostty`; pass `-e` yourself only when you need non-default command execution semantics.

## Build, Test, and Development Commands
- `stow -nv <pkg>` — dry-run to confirm the symlink plan and detect clobbers before writing.
- `stow <pkg>` — deploy a package into `$HOME`; combine with `-t` if targeting alt prefixes.
- `stow -D <pkg>` — remove symlinks for a package; always follow with `stow -nv <pkg>` to ensure cleanup.
- `rg "<pattern>" <pkg>` — preferred search for auditing changes across config files.

## Coding Style & Naming Conventions
- Preserve existing whitespace: two spaces for Lua and shell indentation, four spaces for nested TOML arrays, and no tabs.
- Keep option tables and environment blocks alphabetized where practical (`alacritty.toml`, `zsh/.zshrc`) to simplify diff reviews.
- Use lower-case, hyphen-free directory names for Stow packages; mirror upstream filenames inside (`init.lua`, `alacritty.toml`) without renaming.
- Document non-obvious tweaks with inline comments referencing the source or rationale; avoid redundant narration.
- During refactors, keep existing comments when they remain accurate; revise or drop them only when the behavior they describe changes.

## Commit & Pull Request Guidelines
- Follow the short, imperative message style already in history (`fix alacritty theme`, `bump configs`); scope each commit to one package.
- Reference affected modules in the subject or body (`alacritty`, `neovim`, `zsh`) so stow users can gauge impact quickly.
- PRs must include: summary of intent, list of touched packages, manual verification notes, and any platform caveats.

## Security & Configuration Tips
- Never commit credentials or machine-specific secrets; rely on local excludes or `~/.config` overlays kept outside git.
- Use `stow -nv` before first-time deployment on a host to prevent overwriting existing dotfiles; resolve conflicts explicitly.
- Update `.gitignore` when introducing generated artifacts (caches, compiled outputs) to keep the worktree clean.
- Coordinate environment-wide binaries via `tools/README.md`; note version pins when behavior depends on a specific release.
