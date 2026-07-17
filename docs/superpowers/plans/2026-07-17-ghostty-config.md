# Ghostty Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Ghostty's still-default, auto-generated config with a curated one: an explicitly pinned theme, a Nerd Font (fixing already-broken `eza --icons` rendering), comfortable padding, one added shell-integration feature, and no close-confirmation popup.

**Architecture:** Single file change — `ghostty/.config/ghostty/config` — already a linked stow package (Phase 2's `ghostty/.config/ghostty/config`, no relinking needed). The file's ~40 lines of auto-generated boilerplate comments get replaced by ~10 real setting lines. No code, no new scripts, no new dependencies (font is already installed system-wide; theme is built into Ghostty).

**Tech Stack:** Ghostty 1.3.1-arch2 (GTK runtime, X11), `ghostty +show-config`/`+list-themes` for verification, `fc-match` for font resolution.

## Global Constraints

- Branch: new branch off `main` (name it `ghostty-config`). Never push without being asked.
- `theme = "Ghostty Default Style Dark"` — exact built-in theme name (verified via `ghostty +list-themes` and by diffing its palette against Ghostty's current implicit defaults).
- `font-family = "FiraCode Nerd Font Mono"` — exact family name, already installed system-wide (confirmed via `fc-list`). Do **not** add a `font-feature` line — ligatures are on by default whenever the font supports them; `font-feature` is only for *disabling* ligatures.
- `window-padding-x = 8`, `window-padding-y = 8`, `window-padding-balance = true`.
- `shell-integration-features = sudo` — adds only the `sudo` feature. Do not restate `cursor`/`path`/`title` (already on by default) or `ssh-env`/`ssh-terminfo` (already off, not needed — omitted features keep their existing default, per `ghostty +show-config --default --docs`).
- `confirm-close-surface = false`.
- Keybindings and scrollback: reviewed during brainstorming, deliberately **unchanged**. Do not add keybind lines or a `scrollback-limit` line.
- Preserve the existing `command = /usr/bin/tmux` line (Phase 2) exactly as-is, and preserve its position as the last setting in the file.
- No boilerplate comments in the new file — this repo's convention (see `tmux/.tmux.conf`) is to comment only where the "why" isn't obvious from the line itself.

---

## File Structure

| File | Responsibility |
|---|---|
| `ghostty/.config/ghostty/config` | Entire Ghostty config (MODIFY, existing file — currently the auto-generated first-run template plus one line) |

---

## Task 1: Replace the Ghostty config

**Files:**
- Modify: `~/.dotfiles/ghostty/.config/ghostty/config`

**Interfaces:** None — this is a leaf config file, nothing else in the repo reads it.

- [ ] **Step 1: Failing test (confirm current state)**

```bash
grep -c '^theme' ~/.dotfiles/ghostty/.config/ghostty/config
# expect: 0 (no theme set yet)
grep -c '^font-family' ~/.dotfiles/ghostty/.config/ghostty/config
# expect: 0 (no font set yet)
wc -l < ~/.dotfiles/ghostty/.config/ghostty/config
# expect: ~41 (auto-generated template + the one tmux command line)
```

- [ ] **Step 2: Replace the file's full contents**

Replace the entire contents of `~/.dotfiles/ghostty/.config/ghostty/config` with:

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

- [ ] **Step 3: Verify (passing test)**

```bash
# Parses without error and reflects every new key
ghostty +show-config | grep -E '^(theme|font-family|window-padding-x|window-padding-y|window-padding-balance|shell-integration-features|confirm-close-surface|command) '
```

Expected output (order may vary):
```
theme = Ghostty Default Style Dark
font-family = FiraCode Nerd Font Mono
window-padding-x = 8
window-padding-y = 8
window-padding-balance = true
shell-integration-features = sudo
confirm-close-surface = false
command = /usr/bin/tmux
```

```bash
# Font actually resolves to an installed font file (not a missing-font fallback)
fc-match "FiraCode Nerd Font Mono"
```
Expected: a line naming a `FiraCodeNerdFontMono-*.ttf` file (not a substituted fallback font).

```bash
# Theme is a real built-in theme, not a typo
ghostty +list-themes | grep -F "Ghostty Default Style Dark"
```
Expected: `Ghostty Default Style Dark (resources)`.

**Manual check (Ghostty config changes here hot-reload; `command` doesn't, but it's unchanged):** Reload Ghostty (menu or its reload keybind) or open a new window, then confirm: `ls`/`ll` show file-type icons (not boxes/tofu — this is the `eza --icons` fix), padding looks comfortable, and closing a surface shows no confirmation popup.

- [ ] **Step 4: Commit**

```bash
cd ~/.dotfiles
git add ghostty/.config/ghostty/config
git commit -m "feat(ghostty): pin theme/font, add padding, sudo integration, drop close-confirm"
```

---

## Self-Review Notes

- **Spec coverage:** theme ✅ (Step 2/3), font ✅ (Step 2/3, `fc-match` check), keybindings ✅ (Global Constraints — explicitly left alone), padding ✅ (Step 2/3), shell integration ✅ (Step 2/3), scrollback ✅ (Global Constraints — explicitly left alone), close-confirmation tweak ✅ (Step 2/3). All 7 decision points from the design spec are covered.
- **Placeholder scan:** none found — every step has literal file content and literal commands with expected output.
- **Type/name consistency:** N/A (no code, no function signatures — single declarative config file).
