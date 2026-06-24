# Dotfiles Foundation (Phase 0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `~/.dotfiles` the single source of truth for shell/git/terminal configs, managed by GNU stow, with every live config symlinked from it — non-breaking and fully reversible.

**Architecture:** Each top-level dir in `~/.dotfiles` is a stow "package" whose contents mirror `$HOME`. A `Makefile` wraps the stow commands; a repo `CLAUDE.md` documents the conventions. We first reconcile repo content (repo-only edits, zero impact on the live shell), then perform a single backed-up migration that replaces live files with symlinks.

**Tech Stack:** GNU stow (already installed), GNU make, zsh, git.

## Global Constraints

- Arch Linux, zsh, ghostty are fixed; everything else open.
- Fast, low-bloat; snappiness over maximalism. **No new dependencies** beyond `stow` (already installed) and `make` (standard).
- Reversible changes only; commit to version control as we go.
- Manager is **GNU stow**; convenience layer is a **Makefile**; conventions doc is **CLAUDE.md**.
- **Preserve the TrackGuard managed block verbatim** (umcp/mios/rsrch/tg-hub/tg). Per the privacy refinement, it lives in **`~/.zshrc.local`** (gitignored), sourced from `.zshrc` — NOT committed.
- All work on branch `dev-env-overhaul`. `main` stays untouched. Do **not** push.
- Stow invocation is always `stow --dir=$HOME/.dotfiles --target=$HOME <packages>`.

---

## File Structure

| File | Responsibility |
|---|---|
| `zsh/.zshrc` | Cross-platform skeleton: aliases, omz + plugins, starship, zoxide, OS-specific + local sourcing |
| `zsh/.aliases` | General/list/util/git/tmux/npm/pacman aliases (stale bare-git block removed) |
| `zsh/.zshrc.linux` | Linux-specific: SSH_ASKPASS, ssh-agent, nvm, LM Studio (unchanged) |
| `zsh/.zshrc.macos` | macOS-specific nvm (unchanged) |
| `git/.gitconfig` | Union of repo (url rewrite) + live (gh credential helpers) |
| `ghostty/.config/ghostty/config` | Captured live ghostty config (designed in Phase 4) |
| `cursor/.config/Cursor/User/settings.json` | Captured live Cursor settings (restructured to mirror $HOME) |
| `Makefile` | `help`/`link`/`unlink`/`restow`/`status`/`add` recipes |
| `CLAUDE.md` | Stow conventions for every Claude Code session |
| `README.md` | Rewritten install/usage (stow workflow); remote URL fixed |
| `~/.zshrc.local` | **(not in repo, gitignored)** TrackGuard block, machine-specific |

**Out of repo:** `~/.dotfiles-backup-<timestamp>/` (migration backups, sibling of the repo).

---

## Task 1: Reconcile the zsh package content

**Files:**
- Modify: `~/.dotfiles/zsh/.zshrc`
- Modify: `~/.dotfiles/zsh/.aliases`

**Interfaces:**
- Produces: a `.zshrc` that sources `~/.aliases`, `~/.zshrc.linux`/`~/.zshrc.macos` (by OS), and `~/.zshrc.local`; a `.aliases` with no bare-git `dotfiles` aliases.

- [ ] **Step 1: Failing test — confirm current state lacks the changes**

```bash
grep -c 'docker-compose' ~/.dotfiles/zsh/.zshrc        # expect: 0
grep -c 'zshrc.local'    ~/.dotfiles/zsh/.zshrc        # expect: 0
grep -c 'git-dir'        ~/.dotfiles/zsh/.aliases      # expect: 1 (stale bare-git alias still present)
```
Expected: `0`, `0`, `1`.

- [ ] **Step 2: Restore the full plugin set in `.zshrc`**

Read the file, then replace the plugins line.

Old:
```
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)
```
New:
```
plugins=(archlinux git docker docker-compose sudo zsh-autosuggestions zsh-syntax-highlighting)
```

- [ ] **Step 3: Source `~/.zshrc.local` at the end of `.zshrc`**

Append after the existing OS-specific `case … esac` block:

```sh

# Machine-specific / private overrides (not version-controlled)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

- [ ] **Step 4: Remove the stale bare-git alias block from `.aliases`**

Delete these exact lines (the abandoned bare-git experiment; also fixes the `df` shadow so `df` stays `df -h`):

```
# Dotfiles
alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
alias df="dotfiles"
alias dfs="dotfiles status"
alias dfa="dotfiles add -u"
alias dfcm="dotfiles commit -m"
alias dfp="dotfiles push"
alias dfl="dotfiles pull"
```

- [ ] **Step 5: Verify the edits (passing test)**

```bash
zsh -n ~/.dotfiles/zsh/.zshrc && echo "zshrc syntax OK"
grep -c 'docker-compose'  ~/.dotfiles/zsh/.zshrc      # expect: 1
grep -c 'zshrc.local'     ~/.dotfiles/zsh/.zshrc      # expect: 1
grep -c 'git-dir'         ~/.dotfiles/zsh/.aliases    # expect: 0
grep -c 'alias df='       ~/.dotfiles/zsh/.aliases    # expect: 1 (only df="df -h")
```
Expected: `zshrc syntax OK`, `1`, `1`, `0`, `1`.

- [ ] **Step 6: Commit**

```bash
cd ~/.dotfiles
git add zsh/.zshrc zsh/.aliases
git commit -m "feat(zsh): restore plugins, source .zshrc.local, drop stale bare-git aliases"
```

---

## Task 2: Union-merge the git config

**Files:**
- Modify: `~/.dotfiles/git/.gitconfig`

**Interfaces:**
- Produces: a `.gitconfig` with both the `url … insteadOf` ssh-rewrite (repo) and the `gh` credential helpers (live).

- [ ] **Step 1: Failing test**

```bash
grep -c 'gh auth git-credential' ~/.dotfiles/git/.gitconfig   # expect: 0
```
Expected: `0`.

- [ ] **Step 2: Append the gh credential helper blocks**

Append to the end of `~/.dotfiles/git/.gitconfig`:

```
[credential "https://github.com"]
	helper =
	helper = !/usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
	helper =
	helper = !/usr/bin/gh auth git-credential
```

- [ ] **Step 3: Verify (passing test)**

```bash
git config --file ~/.dotfiles/git/.gitconfig --get url.git@github.com:.insteadOf   # expect: https://github.com/
git config --file ~/.dotfiles/git/.gitconfig --get-all credential.https://github.com.helper
# expect two lines: an empty line, then "!/usr/bin/gh auth git-credential"
```

- [ ] **Step 4: Commit**

```bash
cd ~/.dotfiles
git add git/.gitconfig
git commit -m "feat(git): merge gh credential helpers with url rewrite"
```

---

## Task 3: Scaffold the ghostty and cursor stow packages

**Files:**
- Create: `~/.dotfiles/ghostty/.config/ghostty/config`
- Create: `~/.dotfiles/cursor/.config/Cursor/User/settings.json`
- Delete: `~/.dotfiles/cursor/settings.json` (flat path, wrong for stow)

**Interfaces:**
- Produces: two packages whose internal paths mirror `$HOME`, ready for `stow`.

- [ ] **Step 1: Failing test**

```bash
ls ~/.dotfiles/ghostty/.config/ghostty/config 2>&1          # expect: No such file
ls ~/.dotfiles/cursor/.config/Cursor/User/settings.json 2>&1 # expect: No such file
```

- [ ] **Step 2: Capture the live ghostty config into the package**

```bash
mkdir -p ~/.dotfiles/ghostty/.config/ghostty
cp ~/.config/ghostty/config ~/.dotfiles/ghostty/.config/ghostty/config
```

- [ ] **Step 3: Reconcile and capture Cursor settings (live is source of truth)**

```bash
# Show whether the live settings differ from the tracked flat copy:
diff ~/.dotfiles/cursor/settings.json ~/.config/Cursor/User/settings.json && echo "IDENTICAL" || echo "DIFFER — keeping live"
# Capture live as the source of truth at the mirrored path:
mkdir -p ~/.dotfiles/cursor/.config/Cursor/User
cp ~/.config/Cursor/User/settings.json ~/.dotfiles/cursor/.config/Cursor/User/settings.json
# Remove the old flat tracked file:
git -C ~/.dotfiles rm --quiet cursor/settings.json
```

- [ ] **Step 4: Verify (passing test)**

```bash
test -f ~/.dotfiles/ghostty/.config/ghostty/config && echo "ghostty OK"
test -f ~/.dotfiles/cursor/.config/Cursor/User/settings.json && echo "cursor OK"
test ! -e ~/.dotfiles/cursor/settings.json && echo "flat cursor removed"
```
Expected: `ghostty OK`, `cursor OK`, `flat cursor removed`.

- [ ] **Step 5: Commit**

```bash
cd ~/.dotfiles
git add ghostty cursor
git commit -m "feat(stow): scaffold ghostty and cursor packages mirroring \$HOME"
```

---

## Task 4: Create the Makefile (convenience layer)

**Files:**
- Create: `~/.dotfiles/Makefile`

**Interfaces:**
- Produces: `make link|unlink|restow|status|add|help`. `add` signature: `make add pkg=<package> path=<live-file-path>`.

- [ ] **Step 1: Failing test**

```bash
make -C ~/.dotfiles help 2>&1   # expect: make: *** No rule to make target 'help'
```

- [ ] **Step 2: Write the Makefile**

Create `~/.dotfiles/Makefile` with exactly:

```makefile
# ~/.dotfiles/Makefile — GNU stow management
# Each top-level dir (except docs/) is a stow "package" whose contents mirror $HOME.

DOTFILES := $(HOME)/.dotfiles
PACKAGES := zsh git ghostty cursor
STOW     := stow --dir=$(DOTFILES) --target=$(HOME)

.PHONY: help link unlink restow status add

help:
	@echo "Dotfiles (GNU stow) — targets:"
	@echo "  make link                       symlink all packages into \$$HOME"
	@echo "  make unlink                     remove all symlinks (stow -D)"
	@echo "  make restow                     re-link all packages (after adding files)"
	@echo "  make status                     dry-run: show what stow would change"
	@echo "  make add pkg=<p> path=<file>    move a live file into package <p> and re-link"

link:
	$(STOW) $(PACKAGES)
	@echo "Linked: $(PACKAGES)"

unlink:
	$(STOW) -D $(PACKAGES)
	@echo "Unlinked: $(PACKAGES)"

restow:
	$(STOW) -R $(PACKAGES)
	@echo "Restowed: $(PACKAGES)"

status:
	@$(STOW) -n -v 2 $(PACKAGES) 2>&1 | sed 's/^/  /' || true
	@echo "(no LINK/UNLINK lines above = already in sync)"

# Move a live file under stow management:
#   make add pkg=ghostty path=~/.config/ghostty/config
add:
	@test -n "$(pkg)" -a -n "$(path)" || { echo "usage: make add pkg=<package> path=~/.config/foo/bar"; exit 1; }
	@abs=$$(readlink -f "$(path)"); \
	rel=$${abs#$(HOME)/}; \
	dest="$(DOTFILES)/$(pkg)/$$rel"; \
	mkdir -p "$$(dirname "$$dest")"; \
	mv "$$abs" "$$dest"; \
	echo "moved $$abs -> $$dest"; \
	$(STOW) -R "$(pkg)"; \
	echo "re-linked package: $(pkg)"
```

- [ ] **Step 3: Verify (passing test)**

```bash
make -C ~/.dotfiles help | head -1          # expect: "Dotfiles (GNU stow) — targets:"
make -C ~/.dotfiles -n link                 # expect: prints the stow command, runs nothing
```

- [ ] **Step 4: Commit**

```bash
cd ~/.dotfiles
git add Makefile
git commit -m "feat: add Makefile stow convenience layer"
```

---

## Task 5: Documentation — CLAUDE.md and README

**Files:**
- Create: `~/.dotfiles/CLAUDE.md`
- Modify: `~/.dotfiles/README.md`

**Interfaces:**
- Produces: repo-level guidance so any Claude Code session manages the dotfiles correctly; user-facing install/usage docs reflecting stow.

- [ ] **Step 1: Write CLAUDE.md**

Create `~/.dotfiles/CLAUDE.md` with exactly:

```markdown
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
```

- [ ] **Step 2: Update README.md**

Read `README.md`. Replace the **Philosophy** and **Installation** sections (the manual `ln -s` / bare-git instructions) with the stow workflow below, and fix the clone URL from `dima-skhl` to `dimaskh`.

New Philosophy section:
```markdown
## Philosophy

Managed with GNU stow: configs live in topic packages under `~/.dotfiles`, and
stow symlinks them into `$HOME`. Simple and transparent — symlinks, no rendering
magic — with a `Makefile` so day-to-day management is one command.
```

New Installation/Usage section:
```markdown
## Installation

```bash
git clone git@github.com:dimaskh/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make link        # symlinks every package into $HOME
```

Machine-specific or private shell config (e.g. work aliases) goes in
`~/.zshrc.local`, which is gitignored and sourced by `.zshrc`.

## Usage

| Command | Action |
|---------|--------|
| `make link` | Symlink all packages into `$HOME` |
| `make unlink` | Remove all symlinks |
| `make restow` | Re-link (after adding files) |
| `make status` | Show what stow would change |
| `make add pkg=<p> path=<file>` | Bring a live file under management |
```
```

- [ ] **Step 3: Verify**

```bash
test -f ~/.dotfiles/CLAUDE.md && echo "CLAUDE.md OK"
grep -c 'ln -s'      ~/.dotfiles/README.md     # expect: 0
grep -c 'dima-skhl'  ~/.dotfiles/README.md     # expect: 0
grep -c 'make link'  ~/.dotfiles/README.md     # expect: >=1
```

- [ ] **Step 4: Commit**

```bash
cd ~/.dotfiles
git add CLAUDE.md README.md
git commit -m "docs: add CLAUDE.md conventions; rewrite README for stow workflow"
```

---

## Task 6: Migrate live configs under stow management

This is the single switch-over. It only touches `$HOME` (not the repo), backs up
everything first, and is reversible via the backup dir or `make unlink` + restore.

**Files:**
- Create: `~/.zshrc.local` (gitignored target; holds the TrackGuard block)
- Create: `~/.dotfiles-backup-<timestamp>/` (backups)
- Replace (with symlinks): `~/.zshrc`, `~/.aliases`, `~/.gitconfig`, `~/.config/ghostty/config`, `~/.config/Cursor/User/settings.json`

- [ ] **Step 1: Failing test — confirm targets are still real files, not symlinks**

```bash
for f in ~/.zshrc ~/.aliases ~/.gitconfig ~/.config/ghostty/config ~/.config/Cursor/User/settings.json; do
  test -L "$f" && echo "LINK  $f" || echo "FILE  $f"
done
```
Expected: all `FILE` (none are symlinks yet).

- [ ] **Step 2: Back up every live target**

```bash
BK="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BK"
echo "$BK" > /tmp/dotfiles_backup_path
cp -L ~/.zshrc                              "$BK/.zshrc"
cp -L ~/.aliases                            "$BK/.aliases"
cp -L ~/.gitconfig                          "$BK/.gitconfig"
cp -L ~/.config/ghostty/config              "$BK/ghostty-config"
cp -L ~/.config/Cursor/User/settings.json   "$BK/cursor-settings.json"
ls -la "$BK"
```
Expected: five files listed in the backup dir.

- [ ] **Step 3: Extract the TrackGuard block into `~/.zshrc.local` (verbatim)**

```bash
awk '/^# === TrackGuard \/ Eruptr Claude Code workspaces/,/^# === End TrackGuard workspaces block ===/' \
  "$BK/.zshrc" > ~/.zshrc.local
echo "--- ~/.zshrc.local ---"; cat ~/.zshrc.local
# Sanity: the block must be present and complete
grep -c 'End TrackGuard workspaces block' ~/.zshrc.local   # expect: 1
grep -c "alias umcp"  ~/.zshrc.local                       # expect: 1
```
Expected: the full block printed; both greps `1`.

- [ ] **Step 4: Remove the live targets (now safely backed up)**

```bash
rm ~/.zshrc ~/.aliases ~/.gitconfig ~/.config/ghostty/config ~/.config/Cursor/User/settings.json
```

- [ ] **Step 5: Link all packages**

```bash
make -C ~/.dotfiles link
```
Expected: `Linked: zsh git ghostty cursor` with no stow conflict errors.

- [ ] **Step 6: Verify symlinks resolve into the repo (passing test)**

```bash
for f in ~/.zshrc ~/.aliases ~/.gitconfig ~/.config/ghostty/config ~/.config/Cursor/User/settings.json; do
  printf '%-45s -> %s\n' "$f" "$(readlink "$f")"
done
```
Expected: each prints a path pointing inside `.dotfiles/...`.

- [ ] **Step 7: Verify the live shell behaves identically**

```bash
zsh -i -c '
  echo "node: $(node -v)";
  command -v starship >/dev/null && echo "starship OK";
  type umcp   | head -1;
  type tg-hub | head -1;
  alias | grep -q "gac=" && echo "rich aliases OK";
  print -l ${plugins} | tr "\n" " "; echo
'
```
Expected: `node: v24.14.1`; `starship OK`; `umcp is an alias …`; `tg-hub is a shell function`; `rich aliases OK`; plugins list includes `archlinux docker docker-compose`.

- [ ] **Step 8: Verify reversibility round-trip**

```bash
make -C ~/.dotfiles unlink            # symlinks removed (content remains in repo)
test ! -e ~/.zshrc && echo "unlinked OK"
make -C ~/.dotfiles link              # re-established
test -L ~/.zshrc && echo "relinked OK"
```
Expected: `unlinked OK`, `relinked OK`.

- [ ] **Step 9: Confirm the repo is clean (no commit — this task changed only `$HOME`)**

```bash
git -C ~/.dotfiles status --porcelain    # expect: empty (repo content was committed in Tasks 1–5)
```
The TrackGuard data lives in `~/.zshrc.local` (gitignored) and backups in
`~/.dotfiles-backup-*` (outside the repo) — nothing to commit here.

---

## Task 7: Phase 0 acceptance

**Files:** none (verification only).

- [ ] **Step 1: Run the full success-criteria checklist**

```bash
echo "== symlinks =="
for f in ~/.zshrc ~/.aliases ~/.gitconfig ~/.config/ghostty/config ~/.config/Cursor/User/settings.json; do
  test -L "$f" && echo "OK  $f" || echo "FAIL $f"
done
echo "== git remote in README =="
grep -q 'dimaskh/dotfiles' ~/.dotfiles/README.md && echo "OK readme url"
echo "== branch & cleanliness =="
git -C ~/.dotfiles branch --show-current      # expect: dev-env-overhaul
git -C ~/.dotfiles status --porcelain         # expect: empty
echo "== backup present =="
ls -d ~/.dotfiles-backup-* >/dev/null 2>&1 && echo "OK backup exists"
echo "== TrackGuard private =="
git -C ~/.dotfiles ls-files | grep -q 'zshrc.local' && echo "LEAK" || echo "OK trackguard not tracked"
```
Expected: all `OK`, branch `dev-env-overhaul`, empty status, `OK trackguard not tracked` (never `LEAK`).

- [ ] **Step 2: Open a brand-new terminal**

Manually open a fresh ghostty window and confirm: starship prompt renders,
`umcp`/`mios`/`rsrch`/`tg-hub`/`tg` work, `node -v` is `v24.14.1`. If anything
is wrong, recover with `make -C ~/.dotfiles unlink` and restore from
`$(cat /tmp/dotfiles_backup_path)`.

---

## Self-Review

**Spec coverage:**
- Stow manager → Tasks 3–4, 6. ✓
- Makefile (`add/link/unlink/status`) → Task 4 (adds `restow`; drops the spec's `adopt`, which used `stow --adopt` and would have clobbered our reconciled repo files with live content — replaced by the explicit, backed-up migration in Task 6). ✓
- Repo `CLAUDE.md` → Task 5. ✓
- zsh reconciliation (TrackGuard verbatim, plugins restored, bare-git block removed) → Tasks 1, 6. **Refinement:** TrackGuard → `~/.zshrc.local` (gitignored) instead of committed `.zshrc.linux`, to avoid publishing internal names. ✓
- git union merge → Task 2. ✓
- ghostty/cursor captured as-is → Task 3. ✓
- README rewrite + remote URL fix → Task 5. ✓
- Migration safety (timestamped backups, reversible) → Task 6. ✓
- Success criteria → Task 7. ✓

**Placeholder scan:** No TBD/TODO; every code/edit step shows concrete content and commands. ✓

**Type/Name consistency:** `make add` uses `pkg=`/`path=` consistently across Makefile, CLAUDE.md, README, and Task 4. Package set `zsh git ghostty cursor` consistent throughout. Backup path convention `~/.dotfiles-backup-<timestamp>` consistent. ✓

**Deviations from spec (intentional, flagged):**
1. TrackGuard → `~/.zshrc.local` (gitignored) rather than committed `.zshrc.linux` — privacy. Reversible if the repo is private and the user prefers it tracked.
2. `make adopt` dropped in favor of explicit backed-up migration (Task 6) — avoids `--adopt` overwriting reconciled repo content.
