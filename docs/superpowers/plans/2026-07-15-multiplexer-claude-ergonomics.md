# Multiplexer + Claude Code Ergonomics (Phase 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire tmux in as the terminal-first multiplexer backbone for running multiple concurrent, named-per-project Claude Code sessions, with an fzf session picker and desktop notifications via Claude Code hooks.

**Architecture:** A new `tmux/` stow package holds a minimal `.tmux.conf`. A new `zsh/.functions` file (sourced from `.zshrc`, same guarded pattern as `.aliases`) defines two fully generic helpers — `tmux_workspace()` (create-or-switch a named session, `$TMUX`-aware) and `ws()` (fzf picker over currently running sessions) — containing zero project-specific data. The private, gitignored `~/.zshrc.local` (outside this repo) is updated in place to call `tmux_workspace` with its existing TrackGuard paths. Ghostty's `command = /usr/bin/tmux` (already committed on this branch) auto-starts a session in every window. Claude Code's `Stop`/`Notification` hooks (in `~/.claude/settings.json`, also outside this repo) shell out to `notify-send`.

**Tech Stack:** GNU stow, GNU make, zsh, tmux 3.7b, fzf, notify-send, Claude Code hooks.

## Global Constraints

- All work on branch `phase-2-multiplexer`. `main` stays untouched. Do **not** push.
- Stow invocation is always `stow --dir=$HOME/.dotfiles --target=$HOME <packages>` (via the Makefile).
- Session model: **one named tmux session per project** (`umcp`, `mios`, `rsrch`, `tg-hub`/`tg`), not tabs-in-one-session.
- Creation vs. reattach: **`$TMUX`-aware branching** — outside tmux → `new-session -A`; inside tmux (the common case, since ghostty auto-starts it) → `has-session` guard + `new-session -d` + `switch-client`.
- The launch command runs **only on session creation**, never re-run on reattach/switch.
- Single full-screen pane per workspace — no forced splits.
- No tmux-resurrect/continuum, no TPM plugin manager — YAGNI for now.
- tmux prefix stays the default `Ctrl-b` — not remapped.
- `tx` (tmuxinator) alias is dropped — confirmed not installed. `t`/`ta`/`tls`/`tns`/`tnt` are kept as-is.
- `zsh/.functions` must contain **zero project-specific names/paths** — all private data (`TG_UMCP`, project names, etc.) lives only in `~/.zshrc.local`, never committed.
- `~/.zshrc.local` and `~/.claude/settings.json` are edited directly but **never** `git add`/`git commit`ed from `~/.dotfiles` — they are outside this repo.
- Reversible: every repo change is committed; `git revert` + `make restow` restores the prior state.

---

## File Structure

| File | Responsibility |
|---|---|
| `tmux/.tmux.conf` | Minimal tmux config: mouse, status colors, history limit, renumber-windows (NEW package) |
| `Makefile` | `PACKAGES += tmux` (MODIFY) |
| `zsh/.functions` | Generic `tmux_workspace()` create-or-switch helper + `ws()` fzf picker — no project data (NEW) |
| `zsh/.zshrc` | Source `.functions`, guarded, same pattern as `.aliases` (MODIFY) |
| `zsh/.aliases` | Drop `tx` (tmuxinator, unused); keep other tmux shortcuts (MODIFY) |
| `~/.claude/settings.json` | Add `Stop`/`Notification` hooks → `notify-send` (MODIFY, outside repo, not committed) |
| `~/.zshrc.local` | Wire `umcp`/`mios`/`rsrch`/`tg-hub`/`tg` onto `tmux_workspace` (MODIFY, outside repo, not committed, private) |

**Out of repo (system state):** `~/.tmux.conf` and `~/.functions` symlinks (created by `make restow`); the ghostty systemd service's in-memory config (needs a restart to pick up `command = tmux`, already committed in a prior commit on this branch).

---

## Task 1: `tmux/` stow package + Makefile registration

Repo-only; adds a file and registers a package. No live impact until Task 4 links it.

**Files:**
- Create: `~/.dotfiles/tmux/.tmux.conf`
- Modify: `~/.dotfiles/Makefile`

**Interfaces:**
- Produces: `~/.tmux.conf` once linked (Task 4); `PACKAGES` includes `tmux`. Consumed by Task 4 (link) and Task 7 (acceptance).

- [ ] **Step 1: Failing test**

```bash
test -f ~/.dotfiles/tmux/.tmux.conf && echo "EXISTS" || echo "absent"   # expect: absent
grep -c '^PACKAGES := zsh git ghostty cursor lazygit atuin$' ~/.dotfiles/Makefile   # expect: 1
```

- [ ] **Step 2: Create the tmux config**

```bash
mkdir -p ~/.dotfiles/tmux
```

Create `~/.dotfiles/tmux/.tmux.conf` with exactly:

```
set -g mouse on
set -g status-bg colour235
set -g status-fg colour250
set -g renumber-windows on
set -g history-limit 10000
```

- [ ] **Step 3: Register the package in the Makefile**

In `~/.dotfiles/Makefile`, replace:

```
PACKAGES := zsh git ghostty cursor lazygit atuin
```
with:
```
PACKAGES := zsh git ghostty cursor lazygit atuin tmux
```

- [ ] **Step 4: Verify (passing test)**

```bash
test -f ~/.dotfiles/tmux/.tmux.conf && echo "tmux.conf OK"
grep -q 'PACKAGES := zsh git ghostty cursor lazygit atuin tmux' ~/.dotfiles/Makefile && echo "PACKAGES OK"
# source-file parses against the CURRENT server regardless of whether one is already running
# (unlike `tmux -f file new-session`, which silently ignores -f if a server already exists)
tmux source-file ~/.dotfiles/tmux/.tmux.conf && echo "tmux.conf parses OK"
```

- [ ] **Step 5: Commit**

```bash
cd ~/.dotfiles
git add tmux Makefile
git commit -m "feat(stow): add tmux config package"
```

---

## Task 2: `zsh/.functions` — generic `tmux_workspace()` + `ws()` helpers

Repo-only; the new file isn't sourced live until Task 4 links it (the `.zshrc` edit is guarded so it no-ops until then).

**Files:**
- Create: `~/.dotfiles/zsh/.functions`
- Modify: `~/.dotfiles/zsh/.zshrc`

**Interfaces:**
- Consumes: `tmux` binary, `fzf` binary (already installed, Phase 1).
- Produces: `tmux_workspace(name, dir, cmd)` — create-or-switch a named tmux session. `ws()` — fzf-pick a running session and switch/attach. Both consumed by `~/.zshrc.local` (Task 6, private, outside repo) and verified in Task 4/7.

- [ ] **Step 1: Failing test**

```bash
test -f ~/.dotfiles/zsh/.functions && echo "EXISTS" || echo "absent"   # expect: absent
grep -c 'functions' ~/.dotfiles/zsh/.zshrc   # expect: 0
```

- [ ] **Step 2: Create `zsh/.functions`**

Create `~/.dotfiles/zsh/.functions` with exactly:

```sh
# tmux_workspace: create-or-switch a named tmux session pinned to a directory,
# running <cmd> only the first time the session is created.
tmux_workspace() {
	local name="$1" dir="$2"
	shift 2
	local cmd="$*"
	if [ -n "$TMUX" ]; then
		tmux has-session -t "$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$dir" ${cmd:+"$cmd"}
		tmux switch-client -t "$name"
	else
		tmux new-session -A -s "$name" -c "$dir" ${cmd:+"$cmd"}
	fi
}

# ws: fzf-pick among currently running tmux sessions and switch/attach to it.
ws() {
	local target
	target=$(tmux list-sessions -F '#S' 2>/dev/null | fzf --prompt="workspace> ") || return
	if [ -n "$TMUX" ]; then
		tmux switch-client -t "$target"
	else
		tmux attach -t "$target"
	fi
}
```

- [ ] **Step 3: Source it from `.zshrc`**

In `~/.dotfiles/zsh/.zshrc`, replace:

```
# Aliases (sourced AFTER OMZ so our eza/modern aliases override OMZ's ls/ll/la/l defaults)
[[ -f ~/.aliases ]] && source ~/.aliases
```
with:
```
# Aliases (sourced AFTER OMZ so our eza/modern aliases override OMZ's ls/ll/la/l defaults)
[[ -f ~/.aliases ]] && source ~/.aliases

# tmux workspace helpers (tmux_workspace, ws) — used by the private per-project workspace aliases in ~/.zshrc.local
[[ -f ~/.functions ]] && source ~/.functions
```

- [ ] **Step 4: Verify (passing test)**

```bash
zsh -n ~/.dotfiles/zsh/.zshrc && echo "zshrc syntax OK"
zsh -n ~/.dotfiles/zsh/.functions && echo "functions syntax OK"
grep -q 'tmux_workspace()' ~/.dotfiles/zsh/.functions && echo "tmux_workspace defined"
grep -q '^ws()' ~/.dotfiles/zsh/.functions && echo "ws defined"
grep -ci 'umcp\|mios\|eruptr\|trackguard\|research' ~/.dotfiles/zsh/.functions   # expect: 0 (no project data)
grep -q '\[\[ -f ~/.functions \]\]' ~/.dotfiles/zsh/.zshrc && echo "source line OK"
```

- [ ] **Step 5: Commit**

```bash
cd ~/.dotfiles
git add zsh/.functions zsh/.zshrc
git commit -m "feat(zsh): add generic tmux_workspace and ws helpers"
```

---

## Task 3: `.aliases` cleanup — drop `tx` (tmuxinator, unused)

**Files:**
- Modify: `~/.dotfiles/zsh/.aliases`

**Interfaces:** none (no other task depends on this).

- [ ] **Step 1: Failing test**

```bash
grep -c 'alias tx=' ~/.dotfiles/zsh/.aliases   # expect: 1
```

- [ ] **Step 2: Drop the `tx` line**

In `~/.dotfiles/zsh/.aliases`, replace:

```
# Tmux aliases
alias t="tmux"
alias ta="t a -t"
alias tls="t ls"
alias tns="t new -s"
alias tnt="t new -t"
alias tx="tmuxinator"
```
with:
```
# Tmux aliases
alias t="tmux"
alias ta="t a -t"
alias tls="t ls"
alias tns="t new -s"
alias tnt="t new -t"
```

- [ ] **Step 3: Verify (passing test)**

```bash
grep -c 'alias tx=' ~/.dotfiles/zsh/.aliases     # expect: 0
grep -c 'alias t="tmux"' ~/.dotfiles/zsh/.aliases  # expect: 1
```

- [ ] **Step 4: Commit**

```bash
cd ~/.dotfiles
git add zsh/.aliases
git commit -m "chore(zsh): drop unused tmuxinator alias"
```

---

## Task 4: Link — `make restow`, verify the new symlinks resolve

Links the new `tmux` package and picks up the new `zsh/.functions` file (stow doesn't auto-symlink a file added to an already-linked package — a restow is required).

**Files:** none new (system state — symlinks).

**Interfaces:**
- Consumes: Tasks 1–2 (files must exist in the repo first).
- Produces: `~/.tmux.conf` and `~/.functions` as live symlinks, consumed by Task 6 and Task 7.

- [ ] **Step 1: Failing test**

```bash
test -L ~/.tmux.conf && echo "LINK" || echo "absent"   # expect: absent
test -L ~/.functions && echo "LINK" || echo "absent"    # expect: absent
```

- [ ] **Step 2: Restow**

```bash
make -C ~/.dotfiles restow
```
Expected: `Restowed: zsh git ghostty cursor lazygit atuin tmux` with no conflict errors.

- [ ] **Step 3: Verify the symlinks resolve into the repo**

```bash
for f in ~/.tmux.conf ~/.functions; do
  printf '%-14s -> %s\n' "$f" "$(readlink "$f")"
done
```
Expected: both point inside `.dotfiles/...`.

- [ ] **Step 4: Verify the helpers load in a fresh interactive shell**

```bash
zsh -i -c 'type tmux_workspace; type ws' 2>&1
```
Expected: `tmux_workspace is a shell function`, `ws is a shell function`.

- [ ] **Step 5: Confirm the repo is clean**

```bash
git -C ~/.dotfiles status --porcelain   # expect: empty (this task only touched $HOME symlinks)
```

(No commit — system state only.)

---

## Task 5: Claude Code notification hooks

Adds `Stop` and `Notification` hook entries to `~/.claude/settings.json` — this file is outside `~/.dotfiles` and must never be `git add`/`git commit`ed here.

**Files:**
- Modify: `~/.claude/settings.json`

**Interfaces:** none (independent of the tmux/zsh tasks).

- [ ] **Step 1: Failing test**

```bash
jq '.hooks.Stop' ~/.claude/settings.json          # expect: null
jq '.hooks.Notification' ~/.claude/settings.json  # expect: null
```

- [ ] **Step 2: Add the two hook entries**

In `~/.claude/settings.json`, replace the exact existing `"hooks"` block:

```json
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"/home/dima/.config/nvm/versions/node/v24.14.1/bin/node\" \"/home/dima/.claude/hooks/caveman-activate.js\"",
            "timeout": 5,
            "statusMessage": "Loading caveman mode..."
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"/home/dima/.config/nvm/versions/node/v24.14.1/bin/node\" \"/home/dima/.claude/hooks/caveman-mode-tracker.js\"",
            "timeout": 5,
            "statusMessage": "Tracking caveman mode..."
          }
        ]
      }
    ]
  },
```
with:
```json
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"/home/dima/.config/nvm/versions/node/v24.14.1/bin/node\" \"/home/dima/.claude/hooks/caveman-activate.js\"",
            "timeout": 5,
            "statusMessage": "Loading caveman mode..."
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"/home/dima/.config/nvm/versions/node/v24.14.1/bin/node\" \"/home/dima/.claude/hooks/caveman-mode-tracker.js\"",
            "timeout": 5,
            "statusMessage": "Tracking caveman mode..."
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' 'Session finished' -a 'Claude Code'",
            "timeout": 5
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' 'Needs your input' -a 'Claude Code'",
            "timeout": 5
          }
        ]
      }
    ]
  },
```

(No `matcher` field — confirmed both `Stop` and `Notification` support none, and omitting it matches all occurrences.)

- [ ] **Step 3: Verify JSON validity and the new entries**

```bash
jq . ~/.claude/settings.json > /dev/null && echo "JSON valid"
jq -r '.hooks.Stop[0].hooks[0].command' ~/.claude/settings.json
jq -r '.hooks.Notification[0].hooks[0].command' ~/.claude/settings.json
```
Expected: `JSON valid`, then the two `notify-send ...` command strings printed back.

- [ ] **Step 4: Smoke-test the command standalone**

```bash
notify-send 'Claude Code' 'Session finished' -a 'Claude Code' && echo "notify-send exit OK"
```
Expected: a desktop notification appears; `notify-send exit OK` printed.

(No commit — this file is outside `~/.dotfiles`.)

---

## Task 6: Wire the private `~/.zshrc.local` aliases onto `tmux_workspace`

Modifies the private, gitignored `~/.zshrc.local` (outside `~/.dotfiles`) in place. **Do not** `git add`/`git commit` this file from the dotfiles repo.

**Files:**
- Modify: `~/.zshrc.local`

**Interfaces:**
- Consumes: `tmux_workspace(name, dir, cmd)` (Task 2/4).

- [ ] **Step 1: Failing test**

```bash
grep -c 'tmux_workspace' ~/.zshrc.local   # expect: 0
```

- [ ] **Step 2: Rewrite the alias/function bodies**

In `~/.zshrc.local`, replace the exact existing block:

```sh
# Focused per-repo sessions (resume last session; drop --continue for a fresh one)
alias umcp='cd "$TG_UMCP" && claude --continue'
alias mios='cd "$TG_MIOS" && claude --continue'
alias rsrch='cd "$TG_RESEARCH" && claude --continue'

# Hub session: root in TrackGuard repo (media-control-platform) + reference the other three
tg-hub() {
  local hub="${TG_REPO:-$TG_UMCP}"
  cd "$hub" && claude \
    --add-dir "$TG_UMCP" \
    --add-dir "$TG_MIOS" \
    --add-dir "$TG_RESEARCH"
}

# Open the TrackGuard repo directly; until TG_REPO is set, fall back to the hub
tg() {
  if [ -n "$TG_REPO" ]; then
    cd "$TG_REPO" && claude --continue
  else
    echo "TG_REPO not set yet — launching interim hub (root: UMCP)."
    tg-hub
  fi
}
```
with:
```sh
# Focused per-repo sessions — named tmux session per project, create-or-switch.
# (resumes last Claude session; drop --continue for a fresh one)
alias umcp='tmux_workspace umcp "$TG_UMCP" "claude --continue"'
alias mios='tmux_workspace mios "$TG_MIOS" "claude --continue"'
alias rsrch='tmux_workspace rsrch "$TG_RESEARCH" "claude --continue"'

# Hub session: root in TrackGuard repo (media-control-platform) + reference the other three
tg-hub() {
  local hub="${TG_REPO:-$TG_UMCP}"
  tmux_workspace tg-hub "$hub" "claude --add-dir $TG_UMCP --add-dir $TG_MIOS --add-dir $TG_RESEARCH"
}

# Open the TrackGuard repo directly; until TG_REPO is set, fall back to the hub
tg() {
  if [ -n "$TG_REPO" ]; then
    tmux_workspace tg "$TG_REPO" "claude --continue"
  else
    echo "TG_REPO not set yet — launching interim hub (root: UMCP)."
    tg-hub
  fi
}
```

The env-var exports at the top of the file and the `# === ... ===` block delimiter comments are untouched.

- [ ] **Step 3: Verify (passing test)**

```bash
grep -c 'tmux_workspace' ~/.zshrc.local   # expect: 5 (umcp, mios, rsrch, tg-hub, tg)
zsh -n ~/.zshrc.local && echo "zshrc.local syntax OK"
```

- [ ] **Step 4: Confirm this file stays untracked**

```bash
git -C ~/.dotfiles status --porcelain   # expect: empty — ~/.zshrc.local is outside this repo
```

(No commit — private file, never tracked in `~/.dotfiles`.)

---

## Task 7: Activate ghostty auto-start + Phase 2 acceptance (USER-RUN restart)

**Files:** none (verification + one disruptive system action).

- [ ] **Step 1: Failing-state check — fresh shell already has the new wiring, ghostty does not yet**

```bash
zsh -i -c 'type tmux_workspace; type ws; alias umcp' 2>&1
```
Expected: `tmux_workspace is a shell function`, `ws is a shell function`, and `umcp` alias shows the new `tmux_workspace umcp ...` body — proves Tasks 2/4/6 are wired together correctly in any new shell, independent of ghostty.

- [ ] **Step 2: User restarts the ghostty service**

**USER-RUN — do not run this from the controller.** It closes every currently open ghostty window, potentially including the one this session is running in.

```
! systemctl --user restart app-com.mitchellh.ghostty.service
```

- [ ] **Step 3: User opens a brand-new ghostty window and confirms**

- It drops directly into a tmux session (status bar visible at the bottom).
- Typing `umcp` create-or-switches into a session named `umcp`, cwd pinned to the umcp project directory, `claude --continue` launches once.
- Detaching (`Ctrl-b d`) and running `umcp` again switches back to the same session without relaunching Claude.
- `ws` lists the running session(s) via fzf and switching to one works.

- [ ] **Step 4: User confirms the `Stop` hook fires**

Send Claude Code a trivial prompt in one of the workspace sessions (e.g. `umcp`) and confirm a desktop notification appears once it finishes responding.

- [ ] **Step 5: Run the full acceptance checklist**

```bash
echo "== repo state =="
git -C ~/.dotfiles branch --show-current      # expect: phase-2-multiplexer
git -C ~/.dotfiles status --porcelain         # expect: empty
echo "== tmux package =="
test -L ~/.tmux.conf && echo "OK ~/.tmux.conf linked" || echo "FAIL"
test -L ~/.functions && echo "OK ~/.functions linked" || echo "FAIL"
echo "== helpers =="
zsh -i -c 'type tmux_workspace >/dev/null 2>&1 && echo "OK tmux_workspace"; type ws >/dev/null 2>&1 && echo "OK ws"'
echo "== private wiring (not tracked) =="
git -C ~/.dotfiles ls-files | grep -q 'zshrc.local' && echo "LEAK" || echo "OK zshrc.local not tracked"
grep -q 'tmux_workspace' ~/.zshrc.local && echo "OK aliases wired"
echo "== hooks =="
jq -e '.hooks.Stop and .hooks.Notification' ~/.claude/settings.json >/dev/null && echo "OK hooks present"
echo "== ghostty =="
grep -q 'command = /usr/bin/tmux' ~/.dotfiles/ghostty/.config/ghostty/config && echo "OK ghostty auto-start configured"
```
Expected: all `OK`, branch `phase-2-multiplexer`, empty status, never `LEAK`/`FAIL`.

(No commit — verification only.)

---

## Self-Review

**Spec coverage:**
- Multiplexer = tmux; ghostty auto-start (`command = /usr/bin/tmux`) → already committed on this branch; activated in Task 7. ✓
- Named session per project → Task 2 (`tmux_workspace`) + Task 6 (aliases). ✓
- Launcher UX (both aliases and picker) → Task 2 (`ws`) + Task 6 (aliases). ✓
- `$TMUX`-aware creation vs. reattach → Task 2 implementation, validated hands-on before this plan was written. ✓
- Launch command runs only on creation → Task 2's `has-session` guard. ✓
- Single full-screen pane, no splits → inherent (no split calls anywhere). ✓
- No resurrect/continuum/TPM → Task 1's `.tmux.conf` adds none; called out in constraints. ✓
- tmux prefix left default → Task 1 adds no prefix remap. ✓
- Drop `tx`, keep other tmux aliases → Task 3. ✓
- Notifications via Stop/Notification hooks → Task 5, schema confirmed against current docs before writing. ✓
- Migration/activation order → Tasks 1–7 ordering. ✓
- Success criteria → Task 7. ✓

**Placeholder scan:** No TBD/TODO; every step shows exact before/after content and concrete verification commands. ✓

**Type/name consistency:** `tmux_workspace(name, dir, cmd)` signature identical in Task 2 (definition) and Task 6 (five call sites). `ws()` defined in Task 2, referenced in Task 4 and Task 7 verification. Package name `tmux` in the Makefile (Task 1) matches the `Restowed: ... tmux` expectation in Task 4. ✓

**Deviations from spec (intentional, flagged):**
1. **Linking (Task 4) happens right after the files it depends on are authored (Tasks 1–2)**, rather than at the very end as the spec's §3.6 migration order lists it — `~/.functions` must actually be symlinked before Task 6's private aliases can call `tmux_workspace` in a live shell. This is a refinement of the ordering, not a contradiction of it.
2. **Task 1's verification uses `tmux source-file`, not `tmux -f <file> new-session`** — the spec's own appendix already uses `source-file`; a `-f` flag on `new-session` is silently ignored if a tmux server is already running (the norm here, since ghostty auto-starts one), which would have made the verification a false positive.
