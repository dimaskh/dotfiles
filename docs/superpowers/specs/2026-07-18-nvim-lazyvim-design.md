# nvim config (LazyVim) — design

## 1. Context

nvim is the last untouched item from the original dev-env overhaul goals
(`docs/dev-env-overhaul-prompt.md`, goal 4): "decide between a curated base
(kickstart.nvim / LazyVim / AstroNvim) or a custom config, set it up as a
genuinely usable editor (LSP, treesitter, telescope/fzf, git, format-on-save)
for TypeScript/Node-heavy work." No `~/.config/nvim` exists yet — nvim 0.12.4
is installed but runs with zero configuration.

nvim is invoked today through three popup mechanisms built earlier in this
overhaul: `nvim-at-line` (used by extrakto and directly), `thumbs-open`
(tmux-thumbs hint selection), and `tmux-goto` (fuzzy file/folder finder).
All three always pass a file argument. The user's stated complaint: nvim as
currently invoked through these is "very basic," and they want better look
and feel — but explicitly as a **quick-edit tool** (used via the popups plus
occasional terminal edits), not a replacement for their GUI editors
(Cursor/VSCodium remain primary for real project work).

## 2. Decisions

Reached through brainstorming (comparing LazyVim, AstroNvim, LunarVim,
kickstart.nvim, NvChad against the user's stated requirements: robust,
battle-tested community config — not something built and maintained from
scratch — easy to extend, good looking):

1. **Distribution: LazyVim.** Most actively maintained of the compared
   options, single-maintainer track record (folke, also author of
   `lazy.nvim`/`tokyonight`/`which-key`), one layer of abstraction (plugin
   specs on top of `lazy.nvim` directly — no community-pack layer like
   AstroNvim adds). Plain `~/.config/nvim` directory structure fits a
   stow-managed dotfiles repo with zero friction. Its per-language "extras"
   system directly covers the language list below with minimal config.
   AstroNvim was the closest runner-up (equally legitimate, one extra layer
   of indirection). LunarVim was ruled out for using a nonstandard installer
   that doesn't fit the plain-`~/.config/nvim` stow convention. kickstart.nvim
   was ruled out because it's a starter template meant to be built into your
   own config over time — the opposite of "don't want to build/maintain a
   config from scratch."
2. **Usage pattern: quick-edit tool.** Shapes scope down from "full IDE" —
   no debugging (DAP), no test-runner integration, no session/project
   management. LSP, treesitter, fuzzy-finding, and git integration are what
   matter; heavier IDE tooling is explicitly not needed right now.
3. **Language LSP coverage:** TypeScript/JavaScript/Node, Shell (bash/zsh),
   Lua, Python, Rust, YAML/Docker/JSON. Lua is covered by LazyVim's core
   (it's a Lua-based tool). The rest are enabled via LazyVim's official
   per-language extras where one exists; bash/shell support is added
   manually if no dedicated extra exists. Exact extra identifiers get
   confirmed against LazyVim's current docs/source during planning, not
   hardcoded here.
4. **Theme: LazyVim's default (tokyonight).** No need to match tmux's
   Catppuccin Mocha status bar — user explicitly chose "use the distro's
   default" over forcing consistency.
5. **No changes to the popup scripts.** `nvim-at-line`, `thumbs-open`, and
   `tmux-goto` already invoke `nvim`/`nvim +N -- file` correctly; LazyVim
   doesn't change that contract. LazyVim's dashboard only appears on a bare
   `nvim` with no file argument, so it never shows up through any of the
   three popups.
6. **Git editor and `vim` command: already correct, no change needed.**
   `git/.gitconfig` already sets `core.editor = nvim`, and `zsh/.aliases`
   already has `alias vim='nvim'` (both confirmed live). Once LazyVim is in
   place, both continue to point at the same `nvim` binary with no
   additional wiring.
7. **Dependencies: all already installed.** Confirmed present on this
   machine: `rg`, `fd`, `git`, `node`/`npm` (via nvm), `python3`, `lazygit`,
   a C compiler (`gcc`/`cc`, needed for treesitter parser compilation). No
   package-installation steps needed as part of this work.

## 3. Design

### 3.1 Architecture

Standard LazyVim install: clone the `LazyVim/starter` template, strip its
`.git`, and land the resulting files at `nvim/.config/nvim/` in the dotfiles
repo as a new stow package (`nvim` added to the Makefile's `PACKAGES` list).
The starter's structure is kept as LazyVim intends:

```
nvim/.config/nvim/
  init.lua
  lua/
    config/
      autocmds.lua
      keymaps.lua
      lazy.lua       <- language extras get added here (import spec)
      options.lua
    plugins/
      example.lua    <- template for any future custom plugin additions
```

Customization happens by extending `lua/config/lazy.lua`'s extras imports
and adding files under `lua/plugins/` — following LazyVim's own extension
model, not forking or rewriting its core. First launch of nvim after linking
auto-installs everything: plugins via `lazy.nvim`, LSP servers/formatters via
`mason`, and treesitter parsers — all driven by the already-installed
dependencies above.

### 3.2 Language & tooling scope

Each enabled language extra bundles its LSP server, treesitter parser, and
formatter/linter together (e.g. the TypeScript extra wires up
`typescript-language-server`, the `typescript` treesitter parser, and
`prettier`). LazyVim's core already includes `conform.nvim` with
format-on-save wired in, so enabling an extra is sufficient to get
format-on-save for that language — no separate formatting configuration is
needed, satisfying the original overhaul goal's "format-on-save" requirement.

### 3.3 Look and feel

Distro default theme (tokyonight). Out of the box: bufferline (tabs),
lualine (statusline), neo-tree (file explorer), telescope + fzf-native
(fuzzy finder — satisfies the original "telescope/fzf" goal), which-key
(keybinding hints/discovery), gitsigns, and a `<leader>gg` keymap straight
into the already-installed `lazygit`. Icons render correctly via the FiraCode
Nerd Font already configured in Ghostty (`ghostty/.config/ghostty/config`).

### 3.4 Verification / success criteria

- Opening a file via each of the three popup entry points
  (`nvim-at-line`, `thumbs-open`, `tmux-goto`) shows the full LazyVim UI:
  statusline, correct syntax highlighting, LSP diagnostics for that
  filetype, and correctly rendered icons.
- LSP (hover, go-to-definition, diagnostics, autocomplete) verified working
  for at least one file in each of the 6 covered languages.
- Format-on-save verified for at least one language (e.g. save a `.ts` file,
  confirm `prettier` ran).
- `nvim` stow package links cleanly alongside the existing packages
  (`make status` shows no conflicts).
- `git commit` (no `-m`) opens nvim as the commit-message editor; running
  `vim` from a shell opens nvim. Both already work today and must continue
  to work unchanged.

### 3.5 Out of scope (YAGNI)

- DAP/debugging, test-runner integration (e.g. neotest), session/project
  management, AI-in-editor plugins (Copilot, Avante, etc.) — none requested,
  and none fit "quick-edit tool used via popups."
- Custom colorscheme — using the distro default per the user's explicit
  choice.
- Any change to `nvim-at-line`, `thumbs-open`, or `tmux-goto` — their
  existing contract (invoke `nvim`/`nvim +N -- file`) already works with
  LazyVim as-is.
- Any change to `git/.gitconfig` or `zsh/.aliases` — both already correctly
  point to nvim.
