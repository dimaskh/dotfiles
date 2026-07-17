# Ghostty config — design

## 1. Context

Ghostty is the last unpolished item from the original dev-env overhaul goals
(`docs/dev-env-overhaul-prompt.md`, goal 2). Since the foundation phase, the
live `ghostty/.config/ghostty/config` has only ever gained one line
(`command = /usr/bin/tmux`, Phase 2) — everything else is the auto-generated
template with all options at Ghostty's implicit build defaults.

Ghostty runs as a systemd user service (`app-com.mitchellh.ghostty.service`)
on this machine (Arch Linux, KDE Plasma, X11). Cosmetic options (theme, font,
padding, shell-integration-features, confirm-close-surface) hot-reload via
Ghostty's own reload (new config is picked up on save/reload without
restarting); `command` does not — it only applies to freshly-started
processes, per the Phase 2 spec's note. Not relevant to this design (we're
not touching `command`), but worth carrying forward for whoever edits this
file next.

## 2. Decisions

Reached through brainstorming (research into Ghostty community conventions +
direct inspection of this machine's installed fonts, `ghostty +show-config
--default[--docs]`, and `ghostty +list-themes`):

1. **Font: `FiraCode Nerd Font Mono`, ligatures on.** Already installed
   system-wide (confirmed via `fc-list`). Not just cosmetic: `zsh/.aliases`
   already runs `eza --icons` for `ls`/`ll`/`la`/`lt`, and Ghostty's font was
   completely unset (falling back to its embedded plain "JetBrains Mono",
   not a Nerd Font) — so those icons were almost certainly rendering as
   broken glyphs already. Ligatures need no extra config: Ghostty enables
   them by default whenever the font supports them (`font-feature` is only
   used to *disable* ligatures, e.g. `-calt`).
2. **Theme: `"Ghostty Default Style Dark"`.** User wants to keep Ghostty's
   current look (which is currently just implicit, unset defaults) but have
   it pinned explicitly rather than depend on whatever Ghostty's build
   default happens to be. Found via `grep -rl "282c34"
   /usr/share/ghostty/themes/` — this built-in theme's background
   (`#282c34`), foreground, and 16-color palette match the current
   defaults almost exactly, and it additionally sets `cursor-color`,
   `cursor-text`, and `selection-*`, which are otherwise unset.
3. **Keybindings: no changes.** Ghostty auto-starts tmux in every window
   (Phase 2), so tmux's prefix-based binds are always available, but the
   user explicitly wants Ghostty's native split/tab keybinds
   (`ctrl+shift+o`/`e`, `alt+1-9`, etc.) left alone too, to use both for a
   while before deciding whether to converge on one. Revisit later if
   wanted — not in scope here.
4. **Padding: `8,8` with balance on.** Current default (`2,2`) is cramped;
   `window-padding-balance = true` centers the grid when the window doesn't
   divide evenly into cells.
5. **Shell integration: add `sudo` only.** Confirmed via `ghostty
   +show-config --default --docs`: "If you omit a feature, its default
   value is used, so you must explicitly disable features you don't want."
   So `shell-integration-features = sudo` enables only the sudo-wrapper
   visual indicator; `cursor`/`path`/`title` (already on) and
   `ssh-env`/`ssh-terminfo` (already off, not needed — no remote-host
   workflow) are untouched.
6. **Scrollback: no change.** Default is 10,000,000 bytes, backed by a
   memory-mapped ring buffer — already generous. Reviewed per the original
   goal's checklist, but nothing to change.
7. **New tweak: `confirm-close-surface = false`.** Removes the
   close-confirmation popup the user hits every time a Ghostty window/tab
   closes (default is `true`).

## 3. Design

### 3.1 Full `ghostty/.config/ghostty/config` (assembled, replaces the file)

The current file is still Ghostty's auto-generated first-run template
(~40 lines of boilerplate explaining config syntax) plus the one real
Phase 2 line. This design replaces the whole file with just the real
settings — no boilerplate — matching this repo's terse-commenting
convention (e.g. `tmux/.tmux.conf`: comment only where the "why" isn't
obvious from the line itself):

```
theme = "Ghostty Default Style Dark"
font-family = "FiraCode Nerd Font Mono"

window-padding-x = 8
window-padding-y = 8
window-padding-balance = true

# sudo only: cursor/path/title are already on by default, ssh-env/ssh-terminfo
# aren't needed (no remote-host workflow) — omitted features keep their default
shell-integration-features = sudo

confirm-close-surface = false

command = /usr/bin/tmux
```

The last line (`command = /usr/bin/tmux`) is the pre-existing Phase 2 line,
unchanged — included here only to show the complete assembled file.

### 3.2 Verification

- `ghostty +show-config` (or opening a new window/reloading) reflects every
  new key with no parse errors.
- `fc-match "FiraCode Nerd Font Mono"` resolves to an installed font file.
- A new `ls`/`ll` in a freshly-reloaded window renders eza's file-type icons
  as glyphs, not boxes/tofu.
- Closing a Ghostty surface no longer shows a confirmation popup.

### 3.3 Success criteria

- Icons render correctly for `eza --icons` (currently broken).
- Terminal appearance is pinned to an explicit, version-controlled theme
  rather than implicit build defaults.
- Padding is comfortable; window still centers content via
  `window-padding-balance`.
- No close-confirmation popup.
- Both Ghostty's native splits/tabs and tmux's prefix-based multiplexing
  remain fully available side by side.

### 3.4 Out of scope (YAGNI)

- Converging on a single multiplexing model (native Ghostty vs. tmux) —
  explicitly deferred; user wants to try both first.
- Quick Terminal — not supported on X11 (requires Wayland +
  wlr-layer-shell-v1), which this machine doesn't use.
- Background opacity/blur, cursor style/blink tuning, window-decoration
  changes, custom command-palette entries — cosmetic extras beyond what was
  asked for (would have been "Approach C"); not adopted.
- Changing `command` or anything about the tmux auto-start behavior —
  unrelated to this config's scope.
