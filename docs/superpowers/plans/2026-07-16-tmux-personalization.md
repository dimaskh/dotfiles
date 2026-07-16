# tmux Personalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebind tmux's prefix to `Ctrl-a`, add a set of vim-style convenience keybindings with a self-documenting cheatsheet popup, and wire in a minimal `catppuccin/tmux` status bar via TPM.

**Architecture:** All changes live in the single, already-linked `tmux/.tmux.conf` (Phase 2's package — no new stow package needed). Each task appends a self-contained block: prefix rebind, then keybindings, then the cheatsheet bind, then TPM/catppuccin. TPM itself is cloned to `~/.tmux/plugins/tpm`, outside the repo — same externally-installed pattern as oh-my-zsh, never committed.

**Tech Stack:** tmux 3.7b, TPM (`tmux-plugins/tpm`), `catppuccin/tmux`, GNU stow (package already linked, no relinking needed).

## Global Constraints

- All work continues on the existing branch `phase-2-multiplexer` (Phase 2 hasn't merged yet; this is a direct extension of the same `tmux/` package). `main` stays untouched. Do **not** push.
- Only one file in the repo changes: `tmux/.tmux.conf`. It is already stow-linked to `~/.tmux.conf` — no `make link`/`restow` needed for tmux.conf edits themselves.
- `~/.tmux/plugins/tpm` and everything TPM installs under `~/.tmux/plugins/` live **outside** the repo and are never `git add`/`git commit`ed — same treatment as oh-my-zsh.
- Prefix key: `Ctrl-a`, with `bind-key C-a send-prefix` so a double-tap still reaches the underlying program (e.g. nvim's increment-number binding). This is an accepted, explicit tradeoff — not a bug to fix.
- Every custom `bind`/`bind-key` gets a `-N "description"` annotation, so `tmux list-keys -N` documents it automatically.
- Arrow keys and the default `%`/`"` split bindings are **not** removed — only new bindings are added alongside them.
- Status bar: `catppuccin/tmux`, `mocha` flavor, minimal modules (session name + clock only) — no battery/uptime/application-name modules.
- No session-persistence plugins (tmux-resurrect/continuum), no multi-pane default layouts — still out of scope.
- Reversible: `git revert` of these commits + `tmux source-file ~/.tmux.conf` (or restart tmux) restores Phase 2's plain config. `rm -rf ~/.tmux/plugins` removes TPM/catppuccin manually (outside the repo, not touched by `git revert`).

---

## File Structure

| File | Responsibility |
|---|---|
| `tmux/.tmux.conf` | Grows from Phase 2's 5 lines to include prefix rebind, keybindings, cheatsheet bind, and TPM/catppuccin config (MODIFY, existing file) |

**Out of repo (system state):** `~/.tmux/plugins/tpm` (TPM, `git clone`d once) and `~/.tmux/plugins/tmux` (catppuccin/tmux, fetched by TPM's install script — TPM names the dir after the repo's last path segment, so `catppuccin/tmux` lands at `.../tmux`, not `.../catppuccin`) — external software, not stow-managed, not committed.

---

## Task 1: Prefix rebind

**Files:**
- Modify: `~/.dotfiles/tmux/.tmux.conf`

**Interfaces:**
- Produces: prefix key `C-a` (tmux global option `prefix`). Consumed implicitly by every keybinding added in Tasks 2–3 (they're written as bare `bind`/`bind -r`, which always bind under whatever the current prefix is).

- [ ] **Step 1: Failing test**

```bash
tmux show-options -g prefix   # expect: prefix C-b (still the tmux default)
grep -c 'set -g prefix C-a' ~/.dotfiles/tmux/.tmux.conf   # expect: 0
```

- [ ] **Step 2: Add the prefix rebind**

In `~/.dotfiles/tmux/.tmux.conf`, replace:

```
set -g mouse on
set -g status-bg colour235
set -g status-fg colour250
set -g renumber-windows on
set -g history-limit 10000
```
with:
```
set -g mouse on
set -g renumber-windows on
set -g history-limit 10000

unbind C-b
set -g prefix C-a
bind-key -N "send C-a to the shell/program (double-tap)" C-a send-prefix
```

(`status-bg`/`status-fg` are dropped here — Task 4's catppuccin plugin owns status bar styling, and hand-set colors would just be overridden. Note also the `-N` flag placement: it must appear immediately after `bind-key`/`bind`, before the key — placing it after the command's own arguments makes tmux parse it as an argument to *that command* instead, which errors. This ordering applies to every `-N` annotation in this plan, fixed below in Tasks 2–4.)

- [ ] **Step 3: Verify (passing test)**

```bash
tmux source-file ~/.dotfiles/tmux/.tmux.conf && echo "tmux.conf parses OK"
tmux show-options -g prefix   # expect: prefix C-a
tmux list-keys -N | grep 'send C-a' && echo "double-tap bind present"
```

- [ ] **Step 4: Commit**

```bash
cd ~/.dotfiles
git add tmux/.tmux.conf
git commit -m "feat(tmux): rebind prefix to Ctrl-a"
```

---

## Task 2: Vim-style keybindings (splits, pane nav, resize, reload, copy-mode)

**Files:**
- Modify: `~/.dotfiles/tmux/.tmux.conf`

**Interfaces:**
- Consumes: prefix `C-a` (Task 1) — all binds below are written as bare `bind`/`bind -r`, so they activate under whatever the current prefix is.
- Produces: none consumed by later tasks (Task 3's cheatsheet bind reads these via tmux's own `-N` annotations at runtime, not via any file/code interface).

- [ ] **Step 1: Failing test**

```bash
tmux list-keys -N | grep -c 'split vertical'   # expect: 0
```

- [ ] **Step 2: Add the keybindings**

In `~/.dotfiles/tmux/.tmux.conf`, replace:

```
unbind C-b
set -g prefix C-a
bind-key -N "send C-a to the shell/program (double-tap)" C-a send-prefix
```
with:
```
unbind C-b
set -g prefix C-a
bind-key -N "send C-a to the shell/program (double-tap)" C-a send-prefix

# splits (preserve cwd); defaults (%/") are left bound as a fallback
bind -N "split vertical" | split-window -h -c "#{pane_current_path}"
bind -N "split horizontal" - split-window -v -c "#{pane_current_path}"

# vim-style pane navigation
bind -N "pane left" h select-pane -L
bind -N "pane down" j select-pane -D
bind -N "pane up" k select-pane -U
bind -N "pane right" l select-pane -R

# vim-style pane resize (repeatable: hold prefix once, tap direction repeatedly)
bind -r -N "resize left" H resize-pane -L 5
bind -r -N "resize down" J resize-pane -D 5
bind -r -N "resize up" K resize-pane -U 5
bind -r -N "resize right" L resize-pane -R 5

# reload config without detaching
bind -N "reload config" r source-file ~/.tmux.conf \; display-message "tmux config reloaded"

# vi-style copy-mode motions (hjkl / v to select / y to yank)
setw -g mode-keys vi
bind -T copy-mode-vi -N "begin selection" v send-keys -X begin-selection
bind -T copy-mode-vi -N "copy selection and exit" y send-keys -X copy-selection-and-cancel
```

(`-N` placement: it must come immediately after `bind`/`bind -r`, before the key character — confirmed in an isolated throwaway tmux server during Task 1's review; placing it after the command's own arguments makes tmux parse it as an argument to that command, which errors, e.g. `command split-window: unknown flag -N`.)

- [ ] **Step 3: Verify (passing test)**

```bash
tmux source-file ~/.dotfiles/tmux/.tmux.conf && echo "tmux.conf parses OK"
tmux list-keys -N | grep -c 'split vertical\|split horizontal\|pane left\|pane down\|pane up\|pane right\|resize left\|resize down\|resize up\|resize right\|reload config'   # expect: 11
tmux show-options -gw mode-keys   # expect: mode-keys vi
```

- [ ] **Step 4: Commit**

```bash
cd ~/.dotfiles
git add tmux/.tmux.conf
git commit -m "feat(tmux): add vim-style split/navigation/resize/reload bindings"
```

---

## Task 3: Keybinding cheatsheet popup

**Files:**
- Modify: `~/.dotfiles/tmux/.tmux.conf`

**Interfaces:**
- Consumes: every `-N`-annotated bind from Tasks 1–2 (and this task's own bind) via `tmux list-keys -N` at runtime — no compile-time dependency, just relies on the annotation convention being followed.

- [ ] **Step 1: Failing test**

```bash
tmux list-keys -N | grep -c 'show keybinding cheatsheet'   # expect: 0
```

- [ ] **Step 2: Add the cheatsheet bind**

In `~/.dotfiles/tmux/.tmux.conf`, replace:

```
# vi-style copy-mode motions (hjkl / v to select / y to yank)
setw -g mode-keys vi
bind -T copy-mode-vi -N "begin selection" v send-keys -X begin-selection
bind -T copy-mode-vi -N "copy selection and exit" y send-keys -X copy-selection-and-cancel
```
with:
```
# vi-style copy-mode motions (hjkl / v to select / y to yank)
setw -g mode-keys vi
bind -T copy-mode-vi -N "begin selection" v send-keys -X begin-selection
bind -T copy-mode-vi -N "copy selection and exit" y send-keys -X copy-selection-and-cancel

# keybinding cheatsheet — lists every -N annotated bind above
bind -N "show keybinding cheatsheet" ? display-popup -E "tmux list-keys -N | less"
```

- [ ] **Step 3: Verify (passing test)**

```bash
tmux source-file ~/.dotfiles/tmux/.tmux.conf && echo "tmux.conf parses OK"
tmux list-keys -N | grep 'show keybinding cheatsheet' && echo "cheatsheet bind present"
tmux list-keys -N | wc -l   # sanity: should include all binds from Tasks 1-3 plus tmux's own built-ins
```

- [ ] **Step 4: Commit**

```bash
cd ~/.dotfiles
git add tmux/.tmux.conf
git commit -m "feat(tmux): add list-keys cheatsheet popup bound to prefix ?"
```

---

## Task 4: TPM + catppuccin/tmux status bar

**Files:**
- Modify: `~/.dotfiles/tmux/.tmux.conf`

**Interfaces:** none consumed by later tasks — this is the last config-writing task before acceptance.

- [ ] **Step 1: Failing test**

```bash
test -d ~/.tmux/plugins/tpm && echo "EXISTS" || echo "absent"   # expect: absent
grep -c "@plugin 'catppuccin/tmux'" ~/.dotfiles/tmux/.tmux.conf   # expect: 0
```

- [ ] **Step 2: Clone TPM**

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
Expected: clone succeeds, `~/.tmux/plugins/tpm/tpm` exists and is executable.

- [ ] **Step 3: Add the plugin config**

In `~/.dotfiles/tmux/.tmux.conf`, replace:

```
# keybinding cheatsheet — lists every -N annotated bind above
bind -N "show keybinding cheatsheet" ? display-popup -E "tmux list-keys -N | less"
```
with:
```
# keybinding cheatsheet — lists every -N annotated bind above
bind -N "show keybinding cheatsheet" ? display-popup -E "tmux list-keys -N | less"

# status bar theme (minimal: session name + clock only)
# catppuccin/tmux v2.x ships no default status content — modules are opt-in
# format-string variables (@catppuccin_status_<module>) that must be wired
# into status-left/status-right explicitly (see catppuccin/tmux's
# docs/reference/status-line.md, "Using the theme's built-in status
# modules"). Only session + date_time (clock) are referenced below, so no
# other module (battery/uptime/application-name/etc.) appears.
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'catppuccin/tmux'
set -g @catppuccin_flavor 'mocha'
set -g status-left "#{E:@catppuccin_status_session}"
set -g status-right "#{E:@catppuccin_status_date_time}"
set -g status-left-length 40
set -g status-right-length 40

run '~/.tmux/plugins/tpm/tpm'
```

Note: catppuccin/tmux's exact module/variable names, and whether
`status-left`/`status-right` need explicit content at all, may differ from
a hand-guessed default (its module system has changed across major
versions) — check the plugin's docs (fetched in Step 4) once it's on disk,
and adjust the lines above if needed so the status bar shows only session
name + clock. This is the one step in this plan where the exact config may
need a follow-up tweak based on what the plugin's current docs say, rather
than what's written above.

- [ ] **Step 4: Fetch the plugin via TPM's install script**

```bash
tmux source-file ~/.dotfiles/tmux/.tmux.conf
~/.tmux/plugins/tpm/bin/install_plugins
```
Expected: exit 0, one status line per plugin (e.g. `Installing "tmux"` /
`"tmux" download success`, or `Already installed "..."` on a re-run). The
"Done, press ESCAPE to continue" message is emitted only by TPM's
interactive `prefix I` key-binding path, not by this CLI script — don't
expect it here.

**Directory naming gotcha:** TPM names each plugin's local directory after
the *last path segment* of its `@plugin 'user/repo'` string, not the org
name. Since the repo is `catppuccin/tmux`, TPM fetches it to
`~/.tmux/plugins/tmux/` — **not** `~/.tmux/plugins/catppuccin/` (that path
only exists under catppuccin's own separate, non-TPM "manual install"
method, which this plan doesn't use). Confirm with `ls ~/.tmux/plugins/`.

If the install script errors because it needs an attached client (some TPM
versions shell out assuming one), fall back to a USER-RUN step instead:
attach/switch to any tmux session and press `prefix I` (capital i) to
fetch plugins interactively.

- [ ] **Step 5: Verify (passing test)**

```bash
tmux source-file ~/.dotfiles/tmux/.tmux.conf && echo "tmux.conf parses OK"
test -d ~/.tmux/plugins/tpm && echo "OK tpm present"
test -d ~/.tmux/plugins/tmux && echo "OK catppuccin present (dir named 'tmux', see gotcha above)"
grep -c "@plugin 'catppuccin/tmux'" ~/.dotfiles/tmux/.tmux.conf   # expect: 1
tmux display-message -p "#{E:@catppuccin_status_session}"   # renders the styled session-name segment
tmux display-message -p "#{E:@catppuccin_status_date_time}" # renders the styled clock segment
```

- [ ] **Step 6: Commit**

```bash
cd ~/.dotfiles
git add tmux/.tmux.conf
git commit -m "feat(tmux): add TPM and catppuccin status bar theme"
```

(TPM/catppuccin under `~/.tmux/plugins/` are outside `~/.dotfiles` — not staged, not committed.)

---

## Task 5: Acceptance — visual/interactive verification (USER-RUN)

Automated checks can confirm the config parses and the binds/options exist,
but not that the status bar *looks* right or that a double-tap actually
reaches nvim — those need a human looking at a real terminal.

**Files:** none (verification only).

- [ ] **Step 1: Full non-interactive checklist**

```bash
echo "== repo state =="
git -C ~/.dotfiles branch --show-current      # expect: phase-2-multiplexer
git -C ~/.dotfiles status --porcelain         # expect: empty
echo "== config =="
tmux source-file ~/.dotfiles/tmux/.tmux.conf && echo "OK parses"
tmux show-options -g prefix                   # expect: prefix C-a
tmux show-options -gw mode-keys               # expect: mode-keys vi
tmux list-keys -N | wc -l                     # expect: 13 custom binds + tmux's built-ins
echo "== plugins =="
test -d ~/.tmux/plugins/tpm && echo "OK tpm"
test -d ~/.tmux/plugins/tmux && echo "OK catppuccin (TPM names the dir after the repo's last path segment, 'tmux', not 'catppuccin')"
echo "== not leaked into repo =="
git -C ~/.dotfiles ls-files | grep -q '^tmux/plugins' && echo "LEAK" || echo "OK plugins not tracked"
```
Expected: all `OK`, branch `phase-2-multiplexer`, empty status, never `LEAK`.

- [ ] **Step 2: User attaches to a live tmux session and confirms interactively**

- `Ctrl-a` + `|` opens a vertical split in the current pane's directory; `Ctrl-a` + `-` opens a horizontal one.
- `Ctrl-a h/j/k/l` moves focus between panes.
- `Ctrl-a H/J/K/L` resizes the current pane, repeatable without re-pressing `Ctrl-a`.
- `Ctrl-a r` reloads the config and shows a confirmation message, no detach.
- `Ctrl-a ?` opens a popup listing every annotated binding; scroll with `j`/`k` (via `less`), quit with `q`.
- The status bar shows the catppuccin mocha theme with the session name and a clock, no leftover plain colors.

- [ ] **Step 3: User confirms the nvim double-tap tradeoff**

Open nvim, put the cursor on a number, press `Ctrl-a Ctrl-a`. Expected: the number increments (first `Ctrl-a` is captured by tmux as prefix + passthrough, second reaches nvim).

(No commit — verification only.)

---

## Self-Review

**Spec coverage:**
- Prefix → `Ctrl-a`, double-tap passthrough → Task 1. ✓
- Splits (`|`/`-`, cwd-preserving) → Task 2. ✓
- Vim-style pane nav (`hjkl`) → Task 2. ✓
- Vim-style resize (`HJKL`, repeatable) → Task 2. ✓
- Reload bind (`r`) → Task 2. ✓
- Copy-mode vi motions (flagged addition in the spec) → Task 2. ✓
- Cheatsheet (`list-keys -N` + `display-popup`, bound to `?`) → Task 3. ✓
- TPM install → Task 4 Step 2. ✓
- catppuccin/tmux, mocha flavor, minimal modules → Task 4 Step 3, with an explicit callout to verify module names against the plugin's current README. ✓
- Old `status-bg`/`status-fg` removed (catppuccin now owns styling) → Task 1 Step 2. ✓
- Reversibility → Global Constraints + Task 4's explicit "outside the repo, not committed" note. ✓
- Continue on `phase-2-multiplexer` branch, no new branch → Global Constraints. ✓
- Out of scope (arrow-key unbind, prefix-less fast window switching, extra catppuccin modules, session persistence) → nothing in any task adds these. ✓

**Placeholder scan:** No TBD/TODO; every step shows exact before/after `tmux.conf` content and concrete verification commands. The one deliberately-flagged uncertainty (catppuccin module names) is not a placeholder — it's a documented "verify against upstream docs" callout with a concrete fallback, same pattern the Phase 2 plan used for the Claude Code hooks payload. ✓

**Type/name consistency:** Every `-N` annotation string used in a task's "add" step matches exactly what that same task's "verify" step greps for (e.g. Task 2's `"pane left"` etc. matches its own verify step's grep list). Task 5's `wc -l` count: Task 1 contributes 1 (send-prefix), Task 2 contributes 11 (2 splits + 4 nav + 4 resize + 1 reload), Task 3 contributes 1 (cheatsheet) — **13** custom annotated binds total, matching the corrected comment in Task 5 Step 1. ✓
