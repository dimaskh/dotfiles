# Multiplexer + Claude Code ergonomics — design (Phase 2)

**Date:** 2026-07-15
**Status:** Approved (design); pending implementation plan
**Scope:** Phase 2 of the dev-environment overhaul. Chooses and wires in a
terminal multiplexer as the backbone for running multiple concurrent Claude
Code sessions across the 4 TrackGuard/Eruptr project directories, with a
ghostty auto-start, a named-session-per-project launcher pattern, an fzf
picker, and desktop notifications via Claude Code hooks.

Source kickoff prompt: `docs/dev-env-overhaul-prompt.md` (goals #5 and #7).
Prior phase: `docs/superpowers/specs/2026-06-24-cli-tooling-design.md`.

---

## 1. Context & current-state audit

- Environment: Arch Linux, KDE Plasma (X11), zsh. Terminal is ghostty, which
  runs as a **persistent single-instance background process** (systemd user
  service `app-com.mitchellh.ghostty.service`). This matters for any config
  change to ghostty's `command`: it only takes effect for a freshly-started
  ghostty process. Closing/reopening a *window* against the already-running
  service does **not** re-read the config file — a full service restart
  (`systemctl --user restart app-com.mitchellh.ghostty.service`, disruptive:
  closes every open ghostty window) or the next login is required.
- No multiplexer was previously wired in. `zsh/.aliases` has a dormant
  tmux/tmuxinator alias block (`t`, `ta`, `tls`, `tns`, `tnt`, `tx`) that
  predates this design and was never actively used.
- `~/.zshrc.local` (gitignored, **not** part of this repo, sourced last by
  `.zshrc`) holds the private TrackGuard workspace block: env vars `TG_UMCP`,
  `TG_MIOS`, `TG_RESEARCH`, `TG_REPO`, and aliases/functions `umcp`, `mios`,
  `rsrch`, `tg-hub()`, `tg()` that currently just `cd` + launch
  `claude --continue` / `claude --add-dir ...` directly in the current shell,
  with no multiplexer involved. This file must stay private (internal paths
  and project names) and is edited in place, never committed.
- tmux 3.7b is installed, no pre-existing `~/.tmux.conf` — a clean slate.
- **zellij 0.44.3 was trialed first and initially chosen** (built-in session
  resurrection, felt lower-friction with zero config out of the box) but the
  choice was reversed after hands-on use surfaced real friction: the
  `--session` + `--layout`/`--layout-string` CLI combo only adds a tab to an
  **already-existing** session and errors ("There is no active session!")
  otherwise; a custom `layout { }` block silently drops the default
  tab-bar/status-bar unless it's manually reconstructed (confirmed via
  `zellij setup --dump-layout default`); combined with the ghostty
  single-instance gotcha above, this reproduced the same "config/keybinding
  friction" pattern that caused the user to abandon tmux years ago — just
  with the tools swapped. tmux was chosen instead specifically for its
  simpler, well-documented, single-command create-or-attach idiom. zellij
  remains installed but unused; no action is taken to remove it.
- **Confirmed tmux mechanics** (hands-on validated this session):
  - Outside tmux (no `$TMUX`): `tmux new-session -A -s NAME -c DIR '<cmd>'`
    creates the session if missing, or attaches if present. `<cmd>` runs
    **only** on actual creation — confirmed it does not re-run on a later
    attach.
  - Inside tmux already (`$TMUX` set — the normal case here, since ghostty
    now auto-starts tmux): `tmux new-session` — even with `-A` — refuses to
    nest ("sessions should be nested with care, unset $TMUX to force"). The
    working pattern instead is:
    ```sh
    tmux has-session -t NAME 2>/dev/null || tmux new-session -d -s NAME -c DIR '<cmd>'
    tmux switch-client -t NAME
    ```
    This creates the session **detached** (side-stepping the nesting
    problem) only if it doesn't already exist, then switches the current
    client over. Confirmed idempotent: re-running the same two lines when
    the session already exists skips creation entirely and just switches,
    without re-running `<cmd>`.
- Claude Code hooks: `~/.claude/settings.json` (not part of this repo)
  already has `SessionStart`/`UserPromptSubmit` hooks for the caveman plugin.
  No `Stop`/`Notification` hooks exist yet.
- `notify-send` is present at `/usr/bin/notify-send`; KDE Plasma provides the
  DBus notification service natively — no daemon to install.

---

## 2. Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Multiplexer | **tmux** (reversed from an initial zellij choice) | Both were hands-on trialed; zellij's session/layout CLI reproduced the exact friction pattern that ended the user's prior tmux usage. tmux's `new-session -A` / `has-session` + `switch-client` idioms are simpler and better documented. |
| Ghostty integration | `command = /usr/bin/tmux` (already committed) — every new ghostty window auto-starts a plain, anonymous tmux session | Matches the "terminal is multiplexer-first by default" goal with zero interactive step. |
| Session model | **One named tmux session per project** (`umcp`, `mios`, `rsrch`, `tg-hub`/`tg`), not tabs-in-one-session | Named sessions are reachable from **any** ghostty window/client via alias or picker and persist independently of which window launched them — closer match to "parallel Claude Code sessions across project dirs" than tying a project's availability to one specific window. |
| Launcher UX | **Both**: dedicated per-project aliases and an fzf picker | One-keystroke access to a known project, plus a fuzzy list to jump among whatever's currently running. |
| Creation vs. reattach | `$TMUX`-aware branching: outside tmux → `new-session -A`; inside tmux (the common case) → `has-session` guard + `new-session -d` + `switch-client` | Validated hands-on; avoids the "sessions should be nested" refusal a naive `new-session -A` hits from inside an existing client. |
| Auto-launch command | `claude --continue` (per-project) / `claude --add-dir ...` (hub), run **only on session creation** | Matches current alias behavior; confirmed tmux only executes the shell-command argument at creation, never on reattach/switch. |
| Pane layout | Single full-screen pane per workspace, no forced splits | Start simple; splits can be added manually per-session later. |
| Session persistence | None beyond tmux's normal in-memory session list (no tmux-resurrect/continuum) | YAGNI until proven needed. Sessions survive a ghostty window closing, but not a reboot. |
| Notifications | Claude Code `Stop`/`Notification` hooks shell out to `notify-send` | Decoupled from the multiplexer entirely — fires regardless of which session is in the foreground, more reliable than pane-content monitoring. |
| tmux config file | New minimal `~/.tmux.conf`, stow-managed under a new `tmux/` package | Clean slate; kept intentionally small (mouse mode, status cosmetics, history limit) in line with the "low friction, no config" preference. |
| tmux prefix key | **Left at the default `Ctrl-b`** | No evidence yet that it's a problem; changing it wasn't validated and risks reintroducing exactly the "keybindings felt clunky" friction from before. Revisit only if it actually causes friction in practice. |
| Old tmux aliases | **`t`/`ta`/`tls`/`tns`/`tnt` kept as-is; `tx` dropped** | These generic tmux shortcuts predate this design and were dormant only because tmux wasn't in use — now that it is, they're live and useful again, unchanged. `tx="tmuxinator"` is the one exception: confirmed tmuxinator isn't installed, so it's dead weight, not a repurposable alias. |

---

## 3. Design

### 3.1 Repo layout changes

```
~/.dotfiles/
├── tmux/
│   └── .tmux.conf                        # NEW package — minimal config
├── ghostty/.config/ghostty/config        # MODIFIED (already committed) — command = tmux
└── zsh/
    ├── .functions                        # NEW — generic tmux_workspace() + ws() helpers (no private data)
    └── .aliases                          # MODIFY — drop `tx` (tmuxinator, not installed); keep t/ta/tls/tns/tnt as-is
```

`~/.zshrc.local` (private, not committed) is updated in place to call the new
generic helper with its existing project paths — the private/public split
stays exactly where it already is: mechanism in the repo, project data
outside it.

### 3.2 Shared workspace-launch helper (generic, committed)

`zsh/.functions` (new file, sourced from `.zshrc`):

```sh
tmux_workspace() {
  local name="$1" dir="$2"; shift 2
  local cmd="$*"
  if [ -n "$TMUX" ]; then
    tmux has-session -t "$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$dir" ${cmd:+"$cmd"}
    tmux switch-client -t "$name"
  else
    tmux new-session -A -s "$name" -c "$dir" ${cmd:+"$cmd"}
  fi
}
```

`~/.zshrc.local` then becomes (illustrative — actual edit happens on the
live, private file):

```sh
alias umcp='tmux_workspace umcp "$TG_UMCP" "claude --continue"'
alias mios='tmux_workspace mios "$TG_MIOS" "claude --continue"'
alias rsrch='tmux_workspace rsrch "$TG_RESEARCH" "claude --continue"'
tg-hub() {
  tmux_workspace tg-hub "${TG_REPO:-$TG_UMCP}" \
    "claude --add-dir $TG_UMCP --add-dir $TG_MIOS --add-dir $TG_RESEARCH"
}
tg() {
  if [ -n "$TG_REPO" ]; then
    tmux_workspace tg "$TG_REPO" "claude --continue"
  else
    echo "TG_REPO not set yet — launching interim hub (root: UMCP)."
    tg-hub
  fi
}
```

No project name, path, or internal identifier appears in the committed
`zsh/.functions` file — `tmux_workspace` is fully generic.

### 3.3 fzf session picker

A new function, e.g. `ws` (workspace switch), added to `zsh/.functions`:

```sh
ws() {
  local target
  target=$(tmux list-sessions -F '#S' 2>/dev/null | fzf --prompt="workspace> " --no-preview) || return
  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$target"
  else
    tmux attach -t "$target"
  fi
}
```

v1 lists only **currently running** sessions — no static/predefined list of
the 4 project names merged in. If nothing's running yet, the picker is
empty; use the dedicated alias to create it first. Keeping this simple is a
deliberate YAGNI call, not an oversight.

### 3.4 tmux config (`tmux/.tmux.conf`)

Minimal, matching the "clean slate, no config" preference:

```
set -g mouse on
set -g status-bg colour235
set -g status-fg colour250
set -g renumber-windows on
set -g history-limit 10000
```

No plugin manager (TPM) is wired in. Session-persistence plugins
(tmux-resurrect/continuum) are explicitly out of scope (§3.6). The user's
separate interest in deep tmux customization for its own sake is out of
scope for this wired-in pattern — the same way "keep tmux installed to
explore later" was scoped out of Phase 2 when zellij was still the pick.

### 3.5 Claude Code notification hooks

Add `Stop` and `Notification` hook entries to `~/.claude/settings.json`
(edited directly — this file lives outside the dotfiles repo):

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": "notify-send 'Claude Code' 'Session finished' -a 'Claude Code'" }] }
    ],
    "Notification": [
      { "hooks": [{ "type": "command", "command": "notify-send 'Claude Code' 'Needs your input' -a 'Claude Code'" }] }
    ]
  }
}
```

The exact hook payload available (e.g. whether the session's `cwd` or
project name can be interpolated into the notification body for a richer
message) needs verifying against Claude Code's current hooks schema during
implementation — this is a low-risk, well-documented mechanism, but the
precise JSON shape should be confirmed rather than assumed.

### 3.6 Migration / activation order

1. Repo edits — new `tmux/` package, `zsh/.functions`, `.aliases` cleanup
   (already-committed ghostty change is part of this same phase). Committed
   to the `phase-2-multiplexer` branch.
2. `make link` (stow) to symlink the new `tmux/.tmux.conf`.
3. Update `~/.zshrc.local` in place (private, not committed) to switch the
   existing aliases/functions onto `tmux_workspace`.
4. Add the `Stop`/`Notification` hooks to `~/.claude/settings.json`.
5. Restart the ghostty systemd service (or wait for next login) to pick up
   `command = tmux`.
6. Verify against the acceptance criteria below.

### 3.7 Success criteria

- A new ghostty window (after the service restart) auto-starts tmux.
- `umcp`/`mios`/`rsrch` create-or-switch to their named session, cwd pinned,
  `claude --continue` launched exactly once on first creation.
- Re-running the same alias from a different window switches to the same
  session without relaunching Claude.
- `ws` lists currently running sessions via fzf and switches to the chosen
  one.
- The `Stop` hook fires a desktop notification when a background Claude
  session finishes.
- `tmux source-file ~/.tmux.conf` applies with no errors.
- Fully reversible: `git revert` of the Phase 2 commits + `make restow`
  restores the prior (no-multiplexer) state; `~/.zshrc.local` reverts by
  hand since it isn't tracked here. Run `stow -D tmux` *before* reverting —
  otherwise `tmux` drops out of `Makefile`'s `PACKAGES` first and the later
  `make restow` never unlinks it, leaving `~/.tmux.conf` a dangling symlink.

### 3.8 Out of scope (YAGNI)

- tmux-resurrect / tmux-continuum session persistence across reboot.
- TPM plugin manager or any tmux plugins.
- Multi-pane splits per workspace — single pane only for v1.
- A static/predefined session list in the fzf picker beyond what's currently
  running.
- Changing the tmux prefix key or other deep keybinding customization.
- nvim integration (Phase 5), further zsh/ghostty polish (Phases 3–4).

---

## Appendix — verification commands

```bash
# tmux config loads cleanly
tmux source-file ~/.tmux.conf && echo OK

# workspace helper is defined and generic (no project names inside)
grep -n 'tmux_workspace\|^ws()' ~/.dotfiles/zsh/.functions
grep -ci 'umcp\|mios\|eruptr\|trackguard' ~/.dotfiles/zsh/.functions   # expect 0

# create-or-switch idempotency (run twice, second run should not re-print FIRST-LAUNCH)
tmux has-session -t demo 2>/dev/null || tmux new-session -d -s demo -c /tmp 'echo FIRST-LAUNCH; zsh'
tmux switch-client -t demo

# ghostty auto-start (after service restart)
systemctl --user restart app-com.mitchellh.ghostty.service
# open a new ghostty window and confirm it drops into tmux directly

# notification hook
jq '.hooks.Stop, .hooks.Notification' ~/.claude/settings.json
```
