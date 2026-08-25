# Accelerando OS

Personal workstation configuration managed with
[chezmoi](https://www.chezmoi.io/). The primary target is Arch Linux with Sway;
macOS notes are also available.

## Repository layout

- `dotfiles/` — Chezmoi source tree for `$HOME`
- `scripts/` — repo-managed Node TypeScript commands
- `firefox/` — Firefox preferences and profile installation instructions
- `docs/linux/` — Arch Linux installation and host setup
- `docs/mac/` — macOS setup notes
- `ai/` — coding-agent configuration and automation

## Bootstrap

Install `git` and `chezmoi`, clone this repository to `~/accel-os`, then
initialize and review the dotfiles:

```bash
chezmoi init --source="$HOME/accel-os/dotfiles" --destination="$HOME"
chezmoi diff
chezmoi apply --dry-run --verbose
chezmoi apply
npm install --ignore-scripts
```

Package installation and managed services are derived from host features in
`dotfiles/.chezmoidata/`.

## Verify

```bash
chezmoi doctor
mb-doctor
just check
```

## Guides

- [Arch Linux setup](docs/linux/README.md)
- [macOS setup](docs/mac/README.md)
- [Firefox preferences](firefox/README.md)
- [Retargeting a Git SPR stack](docs/git-spr-retargeting.md)
