# tmux personalization — design

**Date:** 2026-07-16
**Status:** Draft — pending user review
**Scope:** Follow-up deepening of Phase 2's tmux piece. Not one of the
original overhaul phases (0–5) — a personalization pass on the `tmux/`
package Phase 2 already introduced, driven by the user wanting a nicer daily
experience now that tmux is the default multiplexer. Rebinds the prefix key,
adds a small set of vim-style convenience bindings, wires in a minimal
`catppuccin/tmux` status bar (via TPM), and adds a self-documenting
keybinding cheatsheet.

Prior spec: `docs/superpowers/specs/2026-07-15-multiplexer-claude-ergonomics-design.md`
(Phase 2). This doc **revises** three of that doc's explicit decisions —
prefix key, TPM/plugins, and config scope — see §1.

---

## 1. Context & why this revises Phase 2's decisions

Phase 2 shipped a deliberately minimal `~/.tmux.conf` and explicitly decided
**against** changing the prefix key or bringing in a plugin manager (§3.4/3.8
of the Phase 2 spec), reasoning that neither was validated as needed yet and
that `Ctrl-b` default was "no evidence yet that it's a problem."

Since then the user has used tmux for real work and now wants to invest in
it directly: rebind the prefix, add convenient keybindings with a
cheatsheet, and get a nicer-looking status bar. This is exactly the kind of
"revisit only if it causes friction" trigger Phase 2's doc anticipated — the
difference is the friction here is about ergonomics/aesthetics rather than a
functional bug, and it's an explicit ask rather than a discovered blocker.

Research done before this design (community configs, tmux docs, plugin
READMEs) converged on:
- Prefix key conventions: `Ctrl-a` (screen's historic default, most common
  community remap) vs. `Ctrl-Space` vs. backtick. `Ctrl-a` was chosen.
- Cheatsheet mechanisms: tmux's own `list-keys -N` (uses each binding's
  `-N "description"` annotation) piped into `display-popup`, vs. the
  `tmux-which-key` or `tmux-menus` plugins. Built-in was chosen — zero
  dependencies, and every binding added below gets a `-N` annotation so it's
  automatically documented.
- Status bar options: `catppuccin/tmux` vs. `rose-pine/tmux` vs. hand-rolled
  `status-left`/`status-right` vs. `tmux-power`. `catppuccin/tmux` was
  chosen for its polish and configurability without needing to hand-tune
  colors.

**Known, accepted tradeoff:** tmux intercepts `Ctrl-a` in every pane, including
inside nvim, where `Ctrl-a` natively means "increment number under cursor."
The standard passthrough bind (`bind-key C-a send-prefix`, §3.1) means
nvim's binding still works, just as a double-tap (`Ctrl-a Ctrl-a`). The user
explicitly chose to accept this rather than switch prefix keys.

---

## 2. Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Prefix key | **`Ctrl-a`** (was: left at default `Ctrl-b`) | Explicit ask; standard screen-style remap; double-tap passthrough keeps readline/nvim `Ctrl-a` reachable. |
| Status bar | **`catppuccin/tmux`**, minimal module set (session name + clock) | "Minimal but aesthetic" ask; avoids hand-tuning raw `status-left`/`status-right` color codes. |
| Plugin manager | **TPM** (`tmux-plugins/tpm`), installed via `git clone` to `~/.tmux/plugins/tpm` (not stow-managed — same pattern as oh-my-zsh: an externally-installed framework the repo's config sits on top of) | Required by `catppuccin/tmux`. Reverses Phase 2's "no TPM" YAGNI call now that a plugin is actually wanted. |
| Cheatsheet | Built-in `tmux list-keys -N` + `display-popup`, bound to a prefix key | Zero extra dependencies; every custom binding below is self-documenting via its `-N` annotation. |
| Pane splits | `|` → vertical split, `-` → horizontal split, both preserving cwd (`-c "#{pane_current_path}"`) | Mnemonic symbols; defaults (`%`/`"`) don't preserve cwd and aren't visually intuitive. Old bindings kept as fallback (not unbound). |
| Pane navigation | `h`/`j`/`k`/`l` → `select-pane -L/-D/-U/-R` (prefixed) | Matches nvim muscle memory. Arrow keys are left bound as-is — not removed, since removing them wasn't explicitly asked for. |
| Pane resize | `H`/`J`/`K`/`L` → `resize-pane` in 5-cell steps, marked `-r` (repeatable) | Hold prefix once, tap direction repeatedly to keep resizing, standard tmux idiom for resize binds. |
| Reload config | `r` → `source-file ~/.tmux.conf` + confirmation message | Standard convenience; avoids restarting tmux/detaching to test config changes. |
| Copy-mode motions | `setw -g mode-keys vi` | Small addition beyond the literal ask, flagged here for review: makes copy-mode (`prefix [`) use vi-style `hjkl`/`v`/`y` selection instead of emacs-style, matching every other vim-flavored bind in this doc. Strike if unwanted. |
| Config file scope | `tmux/.tmux.conf` grows from Phase 2's 5 lines to include the above, still a single file, no submodules | No need for multi-file config yet — still small enough for one file. |

---

## 3. Design

### 3.1 Prefix rebind

```tmux
unbind C-b
set -g prefix C-a
bind-key -N "send C-a to the shell/program (double-tap)" C-a send-prefix
```

### 3.2 Keybindings

```tmux
# splits (preserve cwd)
bind -N "split vertical" | split-window -h -c "#{pane_current_path}"
bind -N "split horizontal" - split-window -v -c "#{pane_current_path}"

# vim-style pane navigation
bind -N "pane left" h select-pane -L
bind -N "pane down" j select-pane -D
bind -N "pane up" k select-pane -U
bind -N "pane right" l select-pane -R

# vim-style pane resize (repeatable — keep tapping after one prefix press)
bind -r -N "resize left" H resize-pane -L 5
bind -r -N "resize down" J resize-pane -D 5
bind -r -N "resize up" K resize-pane -U 5
bind -r -N "resize right" L resize-pane -R 5

# reload config without detaching
bind -N "reload config" r source-file ~/.tmux.conf \; display-message "tmux config reloaded"

# vi-style copy-mode motions (hjkl / v to select / y to yank)
setw -g mode-keys vi
```

Note: `-N` must appear immediately after `bind`/`bind-key`, before the key
— placing it after the command's own arguments makes tmux parse it as an
argument to that command instead, which errors (confirmed hands-on during
Task 1's implementation review, in an isolated throwaway tmux server).

### 3.3 Cheatsheet popup

```tmux
bind -N "show keybinding cheatsheet" ? display-popup -E "tmux list-keys -N | less"
```

`prefix ?` opens a scrollable popup listing every `-N`-annotated binding —
covers everything added in §3.1/3.2 automatically, plus any future bind that
follows the same `-N` convention.

### 3.4 TPM + catppuccin/tmux

Install TPM once (external, not stow-managed, parallel to how oh-my-zsh is
installed):
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Add to the bottom of `tmux/.tmux.conf` (TPM requires its `run` line to be
last):
```tmux
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'catppuccin/tmux'
set -g @catppuccin_flavor 'mocha'
set -g status-left "#{E:@catppuccin_status_session}"
set -g status-right "#{E:@catppuccin_status_date_time}"
set -g status-left-length 40
set -g status-right-length 40

run '~/.tmux/plugins/tpm/tpm'
```

catppuccin/tmux v2.x ships **no default status content** — every module
(session, date_time/clock, battery, uptime, application name, etc.) is
opt-in via `@catppuccin_status_<module>` format-string variables that must
be wired into `status-left`/`status-right` explicitly, confirmed against
the plugin's `docs/reference/status-line.md` during implementation. Only
`session` and `date_time` are referenced above, so nothing else appears.
Plugins are fetched via TPM's CLI script (`~/.tmux/plugins/tpm/bin/install_plugins`)
or, interactively, `prefix I` (capital i).

**Directory naming gotcha:** TPM names each plugin's local directory after
the *last path segment* of its `@plugin 'user/repo'` string, not the org
name — `catppuccin/tmux` therefore lands at `~/.tmux/plugins/tmux/`, not
`~/.tmux/plugins/catppuccin/` (that path only exists under catppuccin's
own separate, non-TPM "manual install" method).

### 3.5 Full `tmux/.tmux.conf` (assembled)

```tmux
set -g mouse on
set -g renumber-windows on
set -g history-limit 10000

unbind C-b
set -g prefix C-a
bind-key -N "send C-a to the shell/program (double-tap)" C-a send-prefix

bind -N "split vertical" | split-window -h -c "#{pane_current_path}"
bind -N "split horizontal" - split-window -v -c "#{pane_current_path}"

bind -N "pane left" h select-pane -L
bind -N "pane down" j select-pane -D
bind -N "pane up" k select-pane -U
bind -N "pane right" l select-pane -R

bind -r -N "resize left" H resize-pane -L 5
bind -r -N "resize down" J resize-pane -D 5
bind -r -N "resize up" K resize-pane -U 5
bind -r -N "resize right" L resize-pane -R 5

bind -N "reload config" r source-file ~/.tmux.conf \; display-message "tmux config reloaded"
bind -N "show keybinding cheatsheet" ? display-popup -E "tmux list-keys -N | less"

setw -g mode-keys vi

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'catppuccin/tmux'
set -g @catppuccin_flavor 'mocha'
set -g status-left "#{E:@catppuccin_status_session}"
set -g status-right "#{E:@catppuccin_status_date_time}"
set -g status-left-length 40
set -g status-right-length 40

run '~/.tmux/plugins/tpm/tpm'
```

`status-bg`/`status-fg` (Phase 2's hand-rolled cosmetics) are dropped here —
catppuccin now owns status bar styling, so hand-set colors would either be
overridden or conflict.

### 3.6 Migration / activation order

1. Edit `tmux/.tmux.conf` in the repo (this is still the already-linked
   Phase 2 package — no new stow package, no `make link` needed).
2. Clone TPM: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`.
3. `tmux source-file ~/.tmux.conf` (or `prefix r` once the reload bind is
   live) inside a running tmux session.
4. Fetch `catppuccin/tmux` — either `~/.tmux/plugins/tpm/bin/install_plugins`
   from a shell, or interactively `prefix I` inside tmux. Lands at
   `~/.tmux/plugins/tmux/` (TPM's directory-naming behavior, §3.4), not
   `~/.tmux/plugins/catppuccin/`.
5. Verify against the success criteria below.
6. Commit to the existing `phase-2-multiplexer` branch (this work continues
   on it rather than opening a new branch or waiting for a merge decision —
   Phase 2 hasn't been merged/PR'd yet, and this is a direct extension of
   the same `tmux/` package).

### 3.7 Success criteria

- `Ctrl-a` acts as prefix; `Ctrl-a Ctrl-a` passes a literal `Ctrl-a` through
  to the running program (verified in nvim: increments a number).
- `Ctrl-a |` / `Ctrl-a -` split panes, both opening in the current pane's
  cwd.
- `Ctrl-a h/j/k/l` moves focus between panes; `Ctrl-a H/J/K/L` resizes,
  repeatable without re-pressing prefix.
- `Ctrl-a r` reloads config with a visible confirmation message, no detach.
- `Ctrl-a ?` opens a popup listing all annotated bindings.
- Status bar shows the catppuccin mocha theme with session name and clock,
  no leftover Phase 2 raw color-code styling.
- `tmux source-file ~/.tmux.conf` applies with no errors after all changes.
- Fully reversible: `git revert` of these commits + `tmux source-file` (or
  restart tmux) restores Phase 2's plain config; `rm -rf ~/.tmux/plugins`
  removes TPM/catppuccin manually since they're outside the repo (same
  externally-installed pattern as oh-my-zsh — not reverted by `git revert`).

### 3.8 Out of scope (YAGNI)

- Session persistence (tmux-resurrect/continuum) — still not asked for.
- Multi-pane default layouts — still single-pane per workspace at launch.
- Unbinding arrow keys or adding prefix-less (`-n`) fast window-switching
  binds — not explicitly asked for; can be added later if it comes up.
- Any catppuccin modules beyond session name + clock (battery, uptime,
  application name, etc.) — "minimal" was the explicit ask.
- Further zsh/ghostty/nvim polish (Phases 3–5).

---

## Appendix — verification commands

```bash
# config loads cleanly after all edits
tmux source-file ~/.tmux.conf && echo OK

# prefix actually moved
tmux show-options -g prefix

# every custom bind carries a -N annotation (cheatsheet completeness)
tmux list-keys -N

# TPM present, catppuccin fetched (its local dir is named "tmux", per TPM's
# last-path-segment naming convention — not "catppuccin")
ls ~/.tmux/plugins/tpm ~/.tmux/plugins/tmux
```
