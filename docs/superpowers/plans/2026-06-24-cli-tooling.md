# CLI Tooling (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install a coherent set of modern CLI tools and wire them into the stow-managed zsh + git configs, non-breaking and fully reversible.

**Architecture:** Repo edits add an install manifest (`packages.txt` + `make tools`), delta + quality-of-life settings to `git/.gitconfig`, modern aliases and a shell-integration block to the `zsh/` package, and two new per-tool stow packages (`lazygit/`, `atuin/`). Because the live configs are now symlinks into the repo (Phase 0), editing a repo file changes the running shell on next launch — so tools are installed **before** the config edits go live, and shell-startup integration lines are defensively guarded so a missing tool never aborts shell startup.

**Tech Stack:** GNU stow, GNU make, zsh, git, pacman; tools: git-delta, lazygit, atuin, dust, duf, procs, yazi, hyperfine, eza, fzf, bat.

## Global Constraints

- Arch Linux, zsh, ghostty are fixed. No new dependencies beyond the listed tools (all in official `extra`) — no AUR, no cargo.
- All work on branch `dev-env-overhaul`. `main` stays untouched. Do **not** push.
- Stow invocation is always `stow --dir=$HOME/.dotfiles --target=$HOME <packages>` (via the Makefile).
- Alias policy: **replace classics** — `ls/ll/la/l/lt`→eza, `du`→dust, `df`→duf, `ps`→procs. `cat` stays `cat`. Originals reachable via `command <x>`.
- History search: **atuin owns `Ctrl-R` + `Up`**; fzf owns `Ctrl-T` + `Alt-C`. atuin is **local-only** (`auto_sync = false`).
- Shell-startup integration lines (fzf source, atuin eval) MUST be guarded so a missing binary/file never aborts zsh startup.
- The package install (`make tools`) requires interactive sudo — it is **user-run**, never run from a subagent.
- Preserve the existing `.zshrc` structure: `.aliases` → omz → starship → zoxide → **[new integration block]** → OS-specific → `.zshrc.local`. The TrackGuard block stays in `~/.zshrc.local` (untouched).
- Reversible: every repo change is committed; `git revert` + `make restow` restores prior state; `sudo pacman -R` removes tools.

---

## File Structure

| File | Responsibility |
|---|---|
| `packages.txt` | Canonical tool manifest, one package per line (NEW) |
| `Makefile` | `+ tools` target; `PACKAGES += lazygit atuin`; help line (MODIFY) |
| `git/.gitconfig` | `+ core.pager=delta`, `[delta]`, QoL defaults, aliases (MODIFY) |
| `zsh/.aliases` | eza/dust/duf/procs/lazygit/lzd aliases (MODIFY) |
| `zsh/.zshrc` | fzf env+source, bat MANPAGER, `y()` yazi wrapper, atuin init — all guarded (MODIFY) |
| `lazygit/.config/lazygit/config.yml` | lazygit: delta pager + nerd font (NEW package) |
| `atuin/.config/atuin/config.toml` | atuin: local-only, fuzzy (NEW package) |

**Out of repo (system state):** the installed pacman packages; `~/.config/lazygit`, `~/.config/atuin` symlinks; atuin's local history DB at `~/.local/share/atuin/`.

---

## Task 1: Install manifest and `make tools` target

Repo-only; adds a file and a make target. No live impact (does not change the shell or git).

**Files:**
- Create: `~/.dotfiles/packages.txt`
- Modify: `~/.dotfiles/Makefile`

**Interfaces:**
- Produces: `make tools` → `sudo pacman -S --needed - < $(DOTFILES)/packages.txt`. Consumed by Task 2 (user runs it).

- [ ] **Step 1: Failing test — confirm neither exists yet**

```bash
test -f ~/.dotfiles/packages.txt && echo "EXISTS" || echo "absent"   # expect: absent
make -C ~/.dotfiles tools 2>&1 | head -1                              # expect: No rule to make target 'tools'
```

- [ ] **Step 2: Create `packages.txt`**

Create `~/.dotfiles/packages.txt` with exactly:

```
git-delta
lazygit
atuin
dust
duf
procs
yazi
hyperfine
eza
bat
fd
fzf
zoxide
starship
```

- [ ] **Step 3: Add the `tools` target to the Makefile**

In `~/.dotfiles/Makefile`, add `tools` to the `.PHONY` line. Replace:

```
.PHONY: help link unlink restow status add
```
with:
```
.PHONY: help link unlink restow status add tools
```

- [ ] **Step 4: Add the help line for `tools`**

In `~/.dotfiles/Makefile`, replace:

```
	@echo "  make add pkg=<p> path=<file>    move a live file into package <p> and re-link"
```
with:
```
	@echo "  make add pkg=<p> path=<file>    move a live file into package <p> and re-link"
	@echo "  make tools                      install the CLI tools from packages.txt (sudo)"
```

- [ ] **Step 5: Add the `tools` recipe**

In `~/.dotfiles/Makefile`, after the `add` recipe (the last line, `echo "re-linked package: $(pkg)"`), append:

```makefile

# Install the modern CLI tool set (idempotent; --needed skips installed packages).
# Run interactively — sudo prompts for a password.
tools:
	sudo pacman -S --needed - < $(DOTFILES)/packages.txt
```

- [ ] **Step 6: Verify (passing test)**

```bash
test -f ~/.dotfiles/packages.txt && echo "manifest OK"
wc -l < ~/.dotfiles/packages.txt                 # expect: 16 (incl. man-db, man-pages added in activation)
make -C ~/.dotfiles -n tools                     # expect: prints "sudo pacman -S --needed - < /home/dima/.dotfiles/packages.txt"
make -C ~/.dotfiles help | grep -c 'make tools'  # expect: 1
```

- [ ] **Step 7: Commit**

```bash
cd ~/.dotfiles
git add packages.txt Makefile
git commit -m "feat: add packages.txt manifest and make tools install target"
```

---

## Task 2: Install the tools (USER-RUN)

**This task is run by the human, not a subagent** — `sudo` needs a password. The controller pauses here, the user runs the install, then the controller verifies the binaries are present before proceeding. No commit (system state only).

**Files:** none (installs system packages).

- [ ] **Step 1: Failing test — confirm the new tools are missing**

```bash
for t in delta lazygit atuin dust duf procs yazi hyperfine; do
  command -v "$t" >/dev/null && echo "OK $t" || echo "MISSING $t"
done
```
Expected: all `MISSING` (delta's binary is `delta`, from the `git-delta` package).

- [ ] **Step 2: User installs the tools**

The user runs (in their terminal, via the `! ` prefix so sudo can prompt):

```
! make -C ~/.dotfiles tools
```

This installs `git-delta lazygit atuin dust duf procs yazi hyperfine` and reconciles `eza bat fd fzf zoxide starship` (already present, skipped by `--needed`).

- [ ] **Step 3: Verify all binaries resolve (passing test)**

```bash
for t in delta lazygit atuin dust duf procs yazi hyperfine eza bat fd fzf zoxide starship; do
  command -v "$t" >/dev/null && echo "OK $t" || echo "MISSING $t"
done
```
Expected: all `OK`. Do not proceed to Task 3 until every line is `OK`.

---

## Task 3: delta + git quality-of-life config

Modifies `git/.gitconfig` (a live symlink) — git immediately starts using delta as the pager. Safe because Task 2 installed delta.

**Files:**
- Modify: `~/.dotfiles/git/.gitconfig`

**Interfaces:**
- Consumes: `delta` binary (Task 2).
- Produces: `core.pager=delta`; git behavior defaults (`pull.rebase=true`, etc.); `git lg` / `git st` aliases. Lazygit (Task 5) also calls `delta`.

- [ ] **Step 1: Failing test**

```bash
git config --file ~/.dotfiles/git/.gitconfig --get core.pager        # expect: empty (no output)
git config --file ~/.dotfiles/git/.gitconfig --get pull.rebase       # expect: empty
```

- [ ] **Step 2: Add `pager = delta` to the existing `[core]` section**

In `~/.dotfiles/git/.gitconfig`, replace:

```
[core]
	editor = nvim
```
with:
```
[core]
	editor = nvim
	pager = delta
```

- [ ] **Step 3: Append delta + QoL sections**

Append to the end of `~/.dotfiles/git/.gitconfig` (after the last `[credential ...]` block):

```ini
[interactive]
	diffFilter = delta --color-only
[delta]
	navigate = true
	line-numbers = true
	side-by-side = false
[merge]
	conflictstyle = zdiff3
[diff]
	colorMoved = default
[pull]
	rebase = true
[push]
	autoSetupRemote = true
	default = current
[fetch]
	prune = true
[rerere]
	enabled = true
[branch]
	sort = -committerdate
[column]
	ui = auto
[alias]
	lg = log --graph --oneline --decorate --all
	st = status -sb
```

- [ ] **Step 4: Verify (passing test)**

```bash
git config --file ~/.dotfiles/git/.gitconfig --get core.pager          # expect: delta
git config --file ~/.dotfiles/git/.gitconfig --get pull.rebase         # expect: true
git config --file ~/.dotfiles/git/.gitconfig --get delta.navigate      # expect: true
git config --file ~/.dotfiles/git/.gitconfig --get alias.lg            # expect: log --graph --oneline --decorate --all
# existing config preserved:
git config --file ~/.dotfiles/git/.gitconfig --get user.email          # expect: dimaskh.dev@gmail.com
git config --file ~/.dotfiles/git/.gitconfig --get url.git@github.com:.insteadOf  # expect: https://github.com/
# delta actually renders a diff fed on stdin:
printf 'diff --git a/x b/x\n--- a/x\n+++ b/x\n@@ -0,0 +1 @@\n+hi\n' | delta >/dev/null && echo "delta renders OK"
```

- [ ] **Step 5: Commit**

```bash
cd ~/.dotfiles
git add git/.gitconfig
git commit -m "feat(git): add delta pager and quality-of-life defaults"
```

---

## Task 4: zsh integration — aliases and shell-startup block

Modifies `zsh/.aliases` and `zsh/.zshrc` (both live symlinks) — the changes take effect in any **new** shell. Safe because Task 2 installed the tools. Startup-fatal lines are guarded.

**Files:**
- Modify: `~/.dotfiles/zsh/.aliases`
- Modify: `~/.dotfiles/zsh/.zshrc`

**Interfaces:**
- Consumes: `eza dust duf procs lazygit lazydocker fzf bat atuin yazi fd` (Tasks 2; `lazydocker` pre-installed).
- Produces: modern aliases; `Ctrl-T`/`Alt-C` (fzf), `Ctrl-R`/`Up` (atuin) keybindings; `MANPAGER` via bat; `y()` yazi cd-on-quit wrapper.

- [ ] **Step 1: Failing test**

```bash
grep -c 'eza' ~/.dotfiles/zsh/.aliases          # expect: 0
grep -c 'atuin' ~/.dotfiles/zsh/.zshrc          # expect: 0
grep -c 'FZF_DEFAULT_COMMAND' ~/.dotfiles/zsh/.zshrc   # expect: 0
```

- [ ] **Step 2: Replace the List + Utility alias blocks in `.aliases`**

In `~/.dotfiles/zsh/.aliases`, replace this exact block:

```
# List aliases
alias ls="ls --color=auto"
alias la="ls -a"
alias ll="ls -alFh"
alias l="ls"
alias l.="ls -A | egrep '^\.'"

# Utility aliases
alias df="df -h"
```
with:
```
# List aliases (eza)
alias ls="eza --icons --group-directories-first"
alias ll="eza -l --git --icons --group-directories-first"
alias la="eza -la --icons --group-directories-first"
alias l="eza"
alias lt="eza --tree --level=2 --icons"

# Modern replacements (originals via `command <x>`)
alias du="dust"
alias df="duf"
alias ps="procs"
```

- [ ] **Step 3: Add lazygit / lazydocker aliases in `.aliases`**

In `~/.dotfiles/zsh/.aliases`, replace this exact block:

```
# Git aliases
alias gcm='git commit -m'
alias gac="git add . && git commit -a -m "
alias gpu="git push upstream"
alias glu="git pull upstream"
```
with:
```
# Git aliases
alias gcm='git commit -m'
alias gac="git add . && git commit -a -m "
alias gpu="git push upstream"
alias glu="git pull upstream"

# Git / Docker TUIs
alias lg="lazygit"
alias lzd="lazydocker"
```

- [ ] **Step 4: Insert the shell-integration block in `.zshrc`**

In `~/.dotfiles/zsh/.zshrc`, replace this exact block:

```
# Navigation
eval "$(zoxide init zsh)"

# OS-specific
```
with:
```
# Navigation
eval "$(zoxide init zsh)"

# fzf (fd-backed, bat preview) — owns Ctrl-T (files) and Alt-C (cd)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border \
  --preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null || eza --tree --color=always {}'"
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

# bat as man pager
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# yazi: quit into the last directory
y() {
	local tmp; tmp="$(mktemp -t yazi-cwd.XXXXXX)"
	yazi "$@" --cwd-file="$tmp"
	local cwd; cwd="$(command cat -- "$tmp")"
	[[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# atuin — owns Ctrl-R + Up. Evaluated LAST (before OS blocks) so it wins the keybindings.
command -v atuin >/dev/null && eval "$(atuin init zsh)"

# OS-specific
```

- [ ] **Step 5: Verify (passing test)**

```bash
zsh -n ~/.dotfiles/zsh/.zshrc && echo "zshrc syntax OK"
grep -c '="eza' ~/.dotfiles/zsh/.aliases          # expect: 5 (ls, ll, la, l, lt)
grep -c 'alias df=' ~/.dotfiles/zsh/.aliases      # expect: 1 (now duf)
grep -q 'alias df="duf"' ~/.dotfiles/zsh/.aliases && echo "df=duf OK"
grep -q 'command -v atuin' ~/.dotfiles/zsh/.zshrc && echo "atuin guarded OK"
grep -q '/usr/share/fzf/key-bindings.zsh' ~/.dotfiles/zsh/.zshrc && echo "fzf source OK"
# interactive smoke test — must have NO errors, and atuin must own ^R:
zsh -i -c 'alias ls; bindkey "^R"; echo "MANPAGER=$MANPAGER"; type y | head -1' 2>&1
```
Expected: `zshrc syntax OK`; eza count `5`; `df=duf OK`; `atuin guarded OK`; `fzf source OK`; the interactive line shows `ls=...eza...`, `"^R"` bound to an atuin widget (e.g. `atuin-search`), a non-empty `MANPAGER`, and `y is a shell function`. No `command not found` errors.

- [ ] **Step 6: Commit**

```bash
cd ~/.dotfiles
git add zsh/.aliases zsh/.zshrc
git commit -m "feat(zsh): wire in eza/fzf/atuin/bat/yazi integration and modern aliases"
```

---

## Task 5: lazygit + atuin config packages

Creates two new stow packages and registers them in the Makefile `PACKAGES` list. Files are created but not yet linked (Task 6 links them).

**Files:**
- Create: `~/.dotfiles/lazygit/.config/lazygit/config.yml`
- Create: `~/.dotfiles/atuin/.config/atuin/config.toml`
- Modify: `~/.dotfiles/Makefile`

**Interfaces:**
- Consumes: `delta` (lazygit pager).
- Produces: `~/.config/lazygit/config.yml` and `~/.config/atuin/config.toml` once `make link`/`restow` runs (Task 6). `PACKAGES` now includes `lazygit atuin`.

- [ ] **Step 1: Failing test**

```bash
test -e ~/.dotfiles/lazygit/.config/lazygit/config.yml && echo "EXISTS" || echo "absent"  # expect: absent
test -e ~/.dotfiles/atuin/.config/atuin/config.toml && echo "EXISTS" || echo "absent"     # expect: absent
grep -c 'lazygit' ~/.dotfiles/Makefile      # expect: 0 (not yet in PACKAGES)
```

- [ ] **Step 2: Create the lazygit config**

```bash
mkdir -p ~/.dotfiles/lazygit/.config/lazygit
```
Create `~/.dotfiles/lazygit/.config/lazygit/config.yml` with exactly:

```yaml
gui:
  nerdFontsVersion: "3"
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
```

- [ ] **Step 3: Create the atuin config**

```bash
mkdir -p ~/.dotfiles/atuin/.config/atuin
```
Create `~/.dotfiles/atuin/.config/atuin/config.toml` with exactly:

```toml
auto_sync = false
update_check = false
search_mode = "fuzzy"
filter_mode = "global"
style = "compact"
inline_height = 25
```

- [ ] **Step 4: Register the new packages in the Makefile**

In `~/.dotfiles/Makefile`, replace:

```
PACKAGES := zsh git ghostty cursor
```
with:
```
PACKAGES := zsh git ghostty cursor lazygit atuin
```

- [ ] **Step 5: Verify (passing test)**

```bash
test -f ~/.dotfiles/lazygit/.config/lazygit/config.yml && echo "lazygit cfg OK"
test -f ~/.dotfiles/atuin/.config/atuin/config.toml && echo "atuin cfg OK"
grep -q 'PACKAGES := zsh git ghostty cursor lazygit atuin' ~/.dotfiles/Makefile && echo "PACKAGES OK"
# stow dry-run shows it WOULD link the two new packages (no conflicts):
make -C ~/.dotfiles status 2>&1 | grep -E 'lazygit|atuin' | head
```
Expected: `lazygit cfg OK`, `atuin cfg OK`, `PACKAGES OK`; the status dry-run lists LINK actions for `.config/lazygit/config.yml` and `.config/atuin/config.toml` with no conflict errors.

- [ ] **Step 6: Commit**

```bash
cd ~/.dotfiles
git add lazygit atuin Makefile
git commit -m "feat(stow): add lazygit and atuin config packages"
```

---

## Task 6: Activate — link new packages, seed atuin (USER-ASSISTED)

Links the two new packages into `~/.config` and seeds atuin's history DB from the existing zsh history. The `make restow` and `atuin import` can be run by the controller; opening a brand-new terminal for the final check is the user's step.

**Files:**
- Create (symlinks): `~/.config/lazygit/config.yml`, `~/.config/atuin/config.toml`
- Create (system): `~/.local/share/atuin/history.db` (seeded)

- [ ] **Step 1: Failing test — new configs not yet linked**

```bash
test -L ~/.config/lazygit/config.yml && echo "LINK" || echo "absent"   # expect: absent
test -L ~/.config/atuin/config.toml && echo "LINK" || echo "absent"    # expect: absent
```

- [ ] **Step 2: Link all packages (includes the two new ones)**

```bash
make -C ~/.dotfiles restow
```
Expected: `Restowed: zsh git ghostty cursor lazygit atuin` with no conflict errors.

- [ ] **Step 3: Verify the new symlinks resolve into the repo**

```bash
for f in ~/.config/lazygit/config.yml ~/.config/atuin/config.toml; do
  printf '%-40s -> %s\n' "$f" "$(readlink "$f")"
done
```
Expected: each points inside `.dotfiles/...`.

- [ ] **Step 4: Seed atuin from existing zsh history**

```bash
atuin import auto
atuin stats 2>&1 | head -5
```
Expected: import reports a number of commands imported; `atuin stats` prints summary rows (or "no history" only if the prior histfile was empty — acceptable).

- [ ] **Step 5: User opens a brand-new terminal and confirms**

Open a fresh ghostty window. Confirm:
- Prompt renders (starship); no startup errors.
- `ls` shows eza output (icons, grouped dirs).
- `Ctrl-R` opens atuin's search UI; `Ctrl-T` opens fzf file picker.
- `lg` opens lazygit; diffs render via delta.
- `man ls` renders through bat (colorized).
- `node -v` is `v24.14.1`; TrackGuard aliases (`umcp`/`tg-hub`) still work.

- [ ] **Step 6: Confirm the repo is clean (this task changed only `$HOME` + system state)**

```bash
git -C ~/.dotfiles status --porcelain   # expect: empty (all repo content committed in Tasks 1,3,4,5)
```

---

## Task 7: Phase 1 acceptance

**Files:** none (verification only).

- [ ] **Step 1: Run the full success-criteria checklist**

```bash
echo "== binaries =="
for t in delta lazygit atuin dust duf procs yazi hyperfine eza bat fd fzf zoxide starship; do
  command -v "$t" >/dev/null && echo "OK  $t" || echo "FAIL $t"
done
echo "== new config symlinks =="
for f in ~/.config/lazygit/config.yml ~/.config/atuin/config.toml; do
  test -L "$f" && echo "OK  $f" || echo "FAIL $f"
done
echo "== git =="
[ "$(git config --get core.pager)" = "delta" ] && echo "OK core.pager=delta" || echo "FAIL core.pager"
[ "$(git config --get pull.rebase)" = "true" ] && echo "OK pull.rebase=true" || echo "FAIL pull.rebase"
echo "== zsh integration (interactive) =="
zsh -i -c '
  alias ls | grep -q eza && echo "OK ls=eza" || echo "FAIL ls";
  bindkey "^R" | grep -qi atuin && echo "OK ^R=atuin" || echo "FAIL ^R";
  bindkey "^T" | grep -qi fzf && echo "OK ^T=fzf" || echo "FAIL ^T";
  [ -n "$MANPAGER" ] && echo "OK MANPAGER set" || echo "FAIL MANPAGER";
  type y >/dev/null 2>&1 && echo "OK y() defined" || echo "FAIL y()";
' 2>&1
echo "== branch & cleanliness =="
git -C ~/.dotfiles branch --show-current      # expect: dev-env-overhaul
git -C ~/.dotfiles status --porcelain         # expect: empty
echo "== TrackGuard still private =="
git -C ~/.dotfiles ls-files | grep -q 'zshrc.local' && echo "LEAK" || echo "OK trackguard not tracked"
```
Expected: all `OK`, branch `dev-env-overhaul`, empty status, `OK trackguard not tracked` (never `LEAK` / `FAIL`).

- [ ] **Step 2: Spot-check the tools work**

```bash
echo "test" | delta >/dev/null 2>&1; echo "delta exit: $?"   # 0
dust ~/.dotfiles 2>&1 | head -1                               # renders a tree
duf 2>&1 | head -1                                            # renders a table
procs --no-update-check 2>&1 | head -1 || procs 2>&1 | head -1  # renders a process table
```
Expected: each runs without "command not found".

---

## Self-Review

**Spec coverage:**
- Tool set install (8 + wire-in 3) → Tasks 1–2. ✓
- Reproducible install (`packages.txt` + `make tools`) → Task 1. ✓
- Replace-classics aliases → Task 4. ✓
- fzf `Ctrl-T`/`Alt-C` + atuin `Ctrl-R`/`Up` → Task 4. ✓
- bat MANPAGER + fzf preview → Task 4. ✓
- yazi `y()` cd-on-quit, no committed config → Task 4. ✓
- delta + git QoL defaults → Task 3. ✓
- lazygit + atuin config packages, per-tool stow layout → Task 5. ✓
- Activation order (install → configs → link → seed) → Tasks 2, 6. ✓
- atuin `import auto` seed → Task 6. ✓
- Success criteria + verification appendix → Task 7. ✓

**Placeholder scan:** No TBD/TODO; every edit step shows exact old/new content and concrete verification commands. ✓

**Type/Name consistency:** `PACKAGES := zsh git ghostty cursor lazygit atuin` consistent (Task 5 ↔ Task 6 restow output). `make tools` consistent (Tasks 1, 2). delta referenced as pager in both `git/.gitconfig` (Task 3) and lazygit `config.yml` (Task 5). Alias `df="duf"` consistent (Task 4 edit ↔ verify). ✓

**Deviations from spec (intentional, flagged):**
1. **Defensive guards** on the fzf-source and atuin-eval lines (`[[ -f ... ]]` / `command -v atuin`), not shown in the spec's §3.3 snippet. Reason: the live configs are symlinks now, so a missing tool would otherwise abort zsh startup; guards also make the dotfiles safe to `make link` on a fresh machine before `make tools`. An improvement, behavior-identical once tools are installed.
2. **Install precedes config edits** (Task 2 before Tasks 3–4), refining the spec's §3.6 "repo edits first (no live impact)" — which assumed nothing was linked. Since Phase 0 linked everything, repo edits are live; installing first keeps git/zsh clean at all times.
