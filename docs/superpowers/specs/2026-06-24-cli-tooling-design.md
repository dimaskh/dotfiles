# CLI tooling — design (Phase 1)

**Date:** 2026-06-24
**Status:** Approved (design); pending implementation plan
**Scope:** Phase 1 of the dev-environment overhaul. Installs a coherent set of
modern CLI tools and wires them into the stow-managed zsh + git configs. Builds
directly on the Phase 0 dotfiles foundation.

Source kickoff prompt: `docs/dev-env-overhaul-prompt.md`.
Prior phase: `docs/superpowers/specs/2026-06-24-dotfiles-foundation-design.md`.

---

## 1. Context & current-state audit

Environment: Arch Linux, zsh + oh-my-zsh, starship, zoxide, nvm (node v24.14.1),
ghostty. All configs are now stow-managed from `~/.dotfiles` (Phase 0 complete).
No Rust toolchain (`cargo` absent) — all installs come from the official pacman
`extra` repo.

### Key findings that shaped this design

- **`eza` and `fzf` are installed but barely wired in.** `ls`/`ll`/`la` still
  point at coreutils `ls`; there are no fzf keybindings (`Ctrl-R`/`Ctrl-T`) in
  `.zshrc`. Phase 1 is as much *integration* as *installation*.
- **`btop` and `lazydocker` are already installed** — no install needed; only
  alias wiring (`lzd`).
- **`git/.gitconfig` is bare** — no pager, no delta, no diff/merge tooling, no
  quality-of-life defaults.
- **All candidate tools are in official `extra`** (verified):
  `git-delta 0.19.2`, `lazygit 0.62.2`, `atuin 18.16.1`, `yazi 26.5.6`,
  `dust 1.2.4`, `duf 0.9.1`, `procs 0.14.11`, `hyperfine 1.20.0`. No AUR/cargo.
- **fzf shell integration ships at** `/usr/share/fzf/key-bindings.zsh` and
  `/usr/share/fzf/completion.zsh` (Arch package layout).
- **sudo requires a password** in this environment — the package install step
  cannot be run by an automation subagent. The repo carries the *mechanism*; the
  user runs the install command interactively.
- **No explicit history config** in the repo zsh files (omz defaults apply);
  atuin will own history going forward, seeded once from the existing histfile.

---

## 2. Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Tool set | Install `git-delta lazygit atuin dust duf procs yazi hyperfine`; wire in already-installed `eza fzf bat` | User chose the full ("Everything") set. All in official repos; low marginal cost. |
| Alias policy | **Replace classics**: `ls/ll/la/lt`→eza, `du`→dust, `df`→duf, `ps`→procs. `cat` stays `cat`. `bat` used as MANPAGER + fzf preview. | Modern feel without the pipe/paging surprises of aliasing `cat`. Originals always reachable via `command <x>` / `\<x>`. |
| History search | **atuin owns `Ctrl-R` + `Up`**; fzf owns `Ctrl-T` (files) + `Alt-C` (cd). atuin **local-only**, no sync. | atuin's DB + stats are the win for parallel-session work. Local-only matches the project's privacy posture; sync can be enabled later. |
| Git config depth | **delta + QoL defaults** (rebase-on-pull, autoSetupRemote, prune, zdiff3, colorMoved, rerere, branch sort, column ui) | User opted into the opinionated modern git baseline. |
| Stow layout | **Per-tool packages** (`lazygit/`, `atuin/`), consistent with Phase 0. delta → `git/.gitconfig`; zsh integration → existing `zsh/` package. yazi → no config file. | Smallest departure from the established Phase 0 convention. |
| Reproducible install | `packages.txt` + `make tools` (`sudo pacman -S --needed - < packages.txt`), user-run | sudo is interactive; the repo stays the canonical source of the tool list. |

---

## 3. Design

**Goal:** A coherent modern-CLI layer, installed reproducibly and wired into the
stow-managed zsh + git configs, with zero behavior regressions and full
reversibility (stow + git history).

### 3.1 Repo layout changes

```
~/.dotfiles/
├── packages.txt                          # NEW — canonical tool list (one per line)
├── Makefile                              # MODIFY — PACKAGES += lazygit atuin ; add `tools` target
├── lazygit/
│   └── .config/lazygit/config.yml         # NEW package
├── atuin/
│   └── .config/atuin/config.toml          # NEW package
├── git/
│   └── .gitconfig                        # MODIFY — + delta + QoL defaults
└── zsh/
    ├── .aliases                          # MODIFY — eza/dust/duf/procs/lazygit aliases
    └── .zshrc                            # MODIFY — fzf, atuin, bat-manpager, yazi wrapper
```

yazi gets **no committed config** — defaults are good. Only a `y()` shell
wrapper (cd-on-quit) is added to `.zshrc`. A real yazi config is deferred to a
later pass if wanted.

### 3.2 Reproducible install

`packages.txt` (canonical, includes already-installed tools so the file is the
complete source of truth):

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

`make tools` target:

```makefile
tools:
	sudo pacman -S --needed - < $(DOTFILES)/packages.txt
```

The user runs `! make -C ~/.dotfiles tools` (or `make tools`) interactively so
sudo can prompt for a password. `--needed` makes it idempotent (skips already
installed packages).

### 3.3 zsh integration (`zsh/` package)

**`.aliases`** — replace the current `ls` family (lines 9–13) and `df` (line 16):

```sh
# List aliases (eza)
alias ls="eza --icons --group-directories-first"
alias ll="eza -l --git --icons --group-directories-first"
alias la="eza -la --icons --group-directories-first"
alias l="eza"
alias lt="eza --tree --level=2 --icons"

# Modern replacements
alias du="dust"
alias df="duf"
alias ps="procs"

# Git / Docker TUIs
alias lg="lazygit"
alias lzd="lazydocker"
```

`cat` is left unchanged. The `l.` alias (dotfiles list) is dropped — `la`
already shows dotfiles. The existing `df="df -h"` is replaced by `df="duf"`.

**`.zshrc`** — insert a block after the `zoxide init` line (current line 13) and
before the OS-specific `case` block (current line 16):

```sh
# fzf (fd-backed, bat preview) — owns Ctrl-T (files) and Alt-C (cd)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border \
  --preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null || eza --tree --color=always {}'"
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# bat as man pager
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# yazi: quit into the last directory
y() {
	local tmp; tmp="$(mktemp -t yazi-cwd.XXXXXX)"
	yazi "$@" --cwd-file="$tmp"
	local cwd; cwd="$(command cat -- "$tmp")"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# atuin — owns Ctrl-R + Up. Sourced LAST so it wins the keybindings.
eval "$(atuin init zsh)"
```

**Ordering is load-bearing:** fzf is sourced first so it claims `Ctrl-T`/`Alt-C`;
atuin's `init` is evaluated last so it owns `Ctrl-R` and `Up` (atuin's default
zsh binding rebinds both). The block sits before the OS-specific and
`.zshrc.local` sourcing, which do not touch these keys.

### 3.4 delta + git (`git/.gitconfig`)

Append the following sections (existing `[user]`, `[init]`, `[core] editor`,
`[url]`, `[credential]` blocks are preserved; `core.pager` is added to the
existing `[core]` section):

```ini
[core]
	pager = delta
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

`side-by-side = false` is a one-line toggle for later. `git lg` (alias) and the
shell `lg=lazygit` alias live in separate namespaces and do not conflict.

### 3.5 Tool configs

**`lazygit/.config/lazygit/config.yml`** — use delta for diffs, nerd-font icons:

```yaml
gui:
  nerdFontsVersion: "3"
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
```

**`atuin/.config/atuin/config.toml`** — local-only, fuzzy:

```toml
auto_sync = false
update_check = false
search_mode = "fuzzy"
filter_mode = "global"
style = "compact"
inline_height = 25
```

A one-time `atuin import auto` (run during migration) seeds the atuin DB from the
existing zsh history so `Ctrl-R` is useful immediately.

**yazi** — no committed config; the `y()` wrapper in `.zshrc` (§3.3) provides
cd-on-quit. Defaults otherwise.

### 3.6 Migration / activation order

1. Repo edits (Tasks add files/configs) — no live impact; committed.
2. User runs `! make -C ~/.dotfiles tools` — installs the 8 packages (sudo).
3. `make -C ~/.dotfiles link` (or `restow`) — links the new `lazygit`/`atuin`
   packages into `~/.config`.
4. One-time `atuin import auto` then `atuin stats` to confirm seed.
5. Open a fresh shell; verify (acceptance §3.7).

### 3.7 Success criteria

- All 8 new binaries resolve on `PATH`; `eza`/`fzf`/`bat` wired in.
- `ls` resolves to eza; `du`/`df`/`ps` resolve to dust/duf/procs; `cat`
  unchanged.
- `bindkey` shows atuin on `^R` and `Up`; fzf on `^T`; `Alt-C` bound.
- `MANPAGER` set; `man <x>` renders through bat.
- `git config --get core.pager` is `delta`; a real diff renders through delta;
  `pull.rebase` is `true`.
- `lazygit` opens and shows delta-rendered diffs; `y` quits into the last dir.
- `zsh -n ~/.dotfiles/zsh/.zshrc` passes; a fresh interactive shell has no
  errors and identical prompt/nvm/plugin behavior to before.
- Fully reversible: `git revert` of the Phase 1 commits + `make restow`
  restores the prior state; uninstalling packages is `sudo pacman -R`.

### 3.8 Out of scope (YAGNI)

- nvim integration with any of these tools (Phase 5).
- tmux/multiplexer integration (Phase 2).
- atuin sync server / cross-machine history.
- Custom bat themes, custom yazi config, custom delta themes beyond defaults.

---

## Appendix — verification commands

```bash
# binaries
for t in delta lazygit atuin dust duf procs yazi hyperfine eza bat fd fzf; do
  command -v "$t" >/dev/null && echo "OK $t" || echo "MISSING $t"
done

# zsh integration (interactive)
zsh -i -c 'bindkey | grep -E "\\^R|atuin" | head; alias ls; echo "MANPAGER=$MANPAGER"'

# git / delta
git config --get core.pager                  # delta
git config --get pull.rebase                 # true
git -C ~/.dotfiles -c color.ui=always diff HEAD~1 | head   # renders via delta
```
