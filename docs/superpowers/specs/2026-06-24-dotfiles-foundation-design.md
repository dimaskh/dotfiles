# Dotfiles foundation — design (Phase 0)

**Date:** 2026-06-24
**Status:** Approved (design); pending implementation plan
**Scope:** Phase 0 of the dev-environment overhaul. Establishes the dotfiles
management strategy and migrates live configs under it. Later phases (CLI
tooling, multiplexer + Claude Code ergonomics, zsh, ghostty, nvim) are
brainstormed and specced separately when reached — see the Roadmap appendix.

Source kickoff prompt: `docs/dev-env-overhaul-prompt.md`.

---

## 1. Context & current-state audit

Environment: Arch Linux (kernel 6.18 LTS), zsh + oh-my-zsh, starship, zoxide,
nvm (node v24.14.1), ghostty, nvim. Terminal-first overhaul; main use case is
running multiple concurrent Claude Code sessions across 4 project dirs.

Already installed: `ripgrep`, `fd`, `bat`, `eza`, `fzf`, `zoxide`, `stow`, `git`.
Missing (later phases): `delta`, `lazygit`, a multiplexer (`tmux`/`zellij`).

### Key findings that shaped this design

- **Nothing is symlinked.** Live `~/.zshrc`, `~/.gitconfig`,
  `~/.config/ghostty/config`, Cursor settings are independent copies; the repo
  does not yet manage anything.
- **The repo is a cleaner cross-platform refactor the user wrote earlier but
  never activated**, not a stale scaffold. Notably:
  - `zsh/.zshrc.linux` already encodes the live Linux-specifics (`SSH_ASKPASS`,
    nvm Linux path, LM Studio PATH), guarded and OS-aware.
  - `zsh/.aliases` is a rich set (git/pacman/list/util/npm) and contains
    **tmux + tmuxinator aliases** — a signal toward tmux for the Phase 2
    multiplexer decision.
- **nvim, ghostty, starship are essentially unconfigured** (stock / default
  template / defaults) — greenfield in their later phases.
- **Divergences to reconcile** (repo vs live):
  - Live `~/.zshrc` contains the **TrackGuard managed block** (umcp/mios/rsrch/
    tg-hub/tg) — present in *no* repo file. Must be carried over **verbatim**.
  - Plugin drift: repo `.zshrc` = `git sudo zsh-autosuggestions
    zsh-syntax-highlighting`; live also loads `archlinux docker docker-compose`.
  - Stale bare-git aliases in `.aliases` (lines 36-42: `dotfiles`/`df`/`dfs`…)
    from an abandoned bare-git experiment; line 37 `alias df="dotfiles"` shadows
    the `df="df -h"` on line 16 (latent bug). Conflicts with stow — remove.
  - `git/.gitconfig`: live has `gh` credential helpers; repo has a
    `url insteadOf` ssh-rewrite. Each wants the other's half.

### Repository state (verified)

- Git repo, branch `main`, working tree clean except untracked `docs/`.
- Remote: `git@github.com:dimaskh/dotfiles.git`. **README incorrectly says
  `dima-skhl`** — fix during Phase 0.
- `.gitignore` already ignores secrets (`.env`, `*.pem`, `*.key`, `id_rsa*`,
  `.ssh/known_hosts`, `.gnupg/`) and defines a `.zshrc.local` /
  `.gitconfig.local` override pattern. No changes required.

---

## 2. Decisions (cross-cutting)

| Decision | Choice | Rationale |
|---|---|---|
| Build sequence | Foundation → main use case. Phase 0 dotfiles → 1 CLI tools → 2 multiplexer + Claude ergonomics → 3 zsh → 4 ghostty → 5 nvim | Foundation must precede config work so every later file is born managed; main use case (parallel sessions) front-loaded right after. |
| Dotfiles manager | **GNU stow** | Smallest departure from the user's stated "plain git + manual symlinking, no magic" philosophy — automates the `ln -s` they already do. Already installed; zero new deps; maps onto the existing `zsh/ git/ cursor/` layout. chezmoi's templating/secrets/bootstrap solve problems already solved by conditional-sourced files or not present. |
| Convenience layer | **Makefile** (`add`/`link`/`unlink`/`status`/`adopt`) | Zero new dependencies (make is standard on Arch & macOS); portable; self-documenting. `just` rejected to avoid a dependency against the low-bloat preference. |
| Self-management | **Repo `CLAUDE.md`** documenting stow conventions | Durable across Claude Code sessions; version-controlled; the on-theme replacement for a (nonexistent, low-trust) third-party stow skill. |
| Third-party stow skill | **None installed** | Ecosystem search returned only low-trust hits (≤25 installs, unknown authors). Risk > value. |

---

## 3. Phase 0 design — Dotfiles foundation

**Goal:** `~/.dotfiles` becomes the single source of truth managed by stow, with
every live config symlinked from it. Zero behavior change beyond conscious,
reversible improvements. Fully reversible (timestamped backups + `stow -D` +
git history).

### 3.1 Repo layout (stow packages — each top-level dir mirrors `$HOME`)

```
~/.dotfiles/
├── Makefile          # add / link / unlink / status / adopt
├── CLAUDE.md         # teaches every Claude session the stow conventions
├── README.md         # updated: stow workflow; fix remote URL
├── zsh/
│   ├── .zshrc  .aliases  .zshrc.linux  .zshrc.macos
├── git/
│   └── .gitconfig
├── ghostty/
│   └── .config/ghostty/config
└── cursor/
    └── .config/Cursor/User/settings.json
```

`make link` runs `stow zsh git ghostty cursor` → symlinks land at `~/.zshrc`,
`~/.config/ghostty/config`, etc. No paths or flags crafted by hand.

### 3.2 Makefile recipes

| Command | Behavior |
|---|---|
| `make add path=~/.config/foo/bar` | Auto-computes the `$HOME`-mirrored package path, moves the file in, re-stows. Removes the folder-structure tedium that caused prior stow abandonment. |
| `make link` / `make unlink` | `stow` / `stow -D` every package. |
| `make status` | Report what is linked vs. drifted. |
| `make adopt` | One-time bootstrap: pull existing live files into the repo via `stow --adopt`, then `git diff` to review what changed. |

All recipes back up any file they are about to replace to
`~/.dotfiles-backup-<timestamp>/` first.

### 3.3 Reconciliation (per file — all backed up, all reversible)

- **zsh:** Adopt the repo's cross-platform skeleton, then:
  1. Carry the **TrackGuard block in verbatim**, placed in `zsh/.zshrc.linux`
     (it is all absolute Linux paths; runs identically on this machine, keeps
     the main `.zshrc` clean and cross-platform). *[Approved.]*
  2. **Restore the `archlinux/docker/docker-compose` plugins** so nothing drops
     silently. Trimming is deferred to Phase 3, done consciously. *[Approved.]*
  3. **Delete the stale bare-git alias block** (`.aliases` 36-42) and fix the
     `df` shadow. *[Approved.]*
  - Net: shell behaves identically, plus the richer alias set is activated.
- **git:** **Union merge** — keep live's `gh` credential helpers *and* the
  repo's `url insteadOf` ssh-rewrite.
- **ghostty / cursor:** Bring current live files under management as-is
  (designed in their later phases). For cursor, diff live
  `~/.config/Cursor/User/settings.json` against the tracked `cursor/settings.json`
  and keep the live version as source of truth; restructure to the mirrored path.
- **README:** Replace the manual-`ln`/bare-git sections with the stow + Makefile
  workflow; fix the remote URL to `dimaskh`.

### 3.4 Migration safety

Before any file is replaced by a symlink, copy it to
`~/.dotfiles-backup-<timestamp>/`. Then `stow`. Recovery paths: `make unlink` +
restore from backup, or `git revert`. No destructive single step.

### 3.5 Success criteria

- `~/.zshrc`, `~/.gitconfig`, `~/.config/ghostty/config`, and the Cursor
  settings are symlinks into `~/.dotfiles`.
- A fresh `zsh` login session has identical behavior: starship prompt, zoxide,
  nvm + node v24.14.1, all current omz plugins, the TrackGuard aliases
  (umcp/mios/rsrch/tg-hub/tg) working, plus the activated alias set.
- `make unlink` cleanly restores an unmanaged state; `make link` re-establishes it.
- All changes committed; backups present; nothing uncommitted left behind
  except intended local overrides.

---

## Appendix — Roadmap (later phases, brainstormed when reached)

Each phase gets its own brainstorm → spec → plan → implement cycle. Open
questions to resolve at that time:

- **Phase 1 — CLI tooling:** install `delta`, `lazygit`; confirm the coherent
  set; wire into zsh/git/nvim. Open: exact tool list, delta vs. alternatives.
- **Phase 2 — Multiplexer + Claude Code ergonomics (main use case):** tmux vs.
  zellij (early signal: existing tmux/tmuxinator aliases lean tmux); session
  persistence; a launcher keeping the 4 workspaces one keystroke apart;
  statusline, `/fast`, resume/continue, notifications.
- **Phase 3 — zsh:** oh-my-zsh vs. lighter (zinit/z4h/antidote); prompt,
  completion, history, keybindings; trim plugins; organize aliases.
- **Phase 4 — ghostty:** theme, nerd font, keybindings, padding, shell
  integration, scrollback.
- **Phase 5 — nvim:** curated base (kickstart/LazyVim/AstroNvim) vs. custom;
  LSP, treesitter, telescope/fzf, git, format-on-save for TypeScript/Node.

### Constraints (apply to all phases)
- Arch Linux, zsh, ghostty are fixed; everything else open.
- Fast, low-bloat; snappiness over maximalism.
- Show tradeoffs, recommend a default, let the user choose at each decision point.
- Reversible changes only; commit to version control as we go.
- **Preserve the TrackGuard managed block verbatim** — it is part of a separate
  active workflow.
