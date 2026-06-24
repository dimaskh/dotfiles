# Dotfiles — repository conventions

This repo is managed with **GNU stow**. Each top-level directory (except `docs/`)
is a stow **package** whose contents mirror `$HOME`.

## Layout
- `zsh/`, `git/` — flat dotfiles (`zsh/.zshrc` → `~/.zshrc`).
- `ghostty/`, `cursor/` — nested configs (`ghostty/.config/ghostty/config` → `~/.config/ghostty/config`).

## Managing
- `make link` / `make unlink` / `make restow` — (un)symlink all packages.
- `make status` — dry-run of what stow would change.
- `make add pkg=<package> path=<live-file>` — move a live file into a package and re-link.
  Example: `make add pkg=ghostty path=~/.config/ghostty/config`.

## Adding a new config (the normal way)
Just ask: "add <path> to dotfiles". The assistant: picks/creates the package,
runs `make add`, verifies the symlink, and commits.

## Rules
- **Never commit secrets.** `.gitignore` already excludes keys, `.env`, ssh/gnupg.
- **Machine-specific or private shell config goes in `~/.zshrc.local`** (gitignored),
  which `.zshrc` sources last. The TrackGuard workspace block lives there — keep it
  verbatim; do not move it into a committed file.
- Edits to a managed file are made **in the repo** (the live path is a symlink).
- Work on a feature branch; never push without being asked.
