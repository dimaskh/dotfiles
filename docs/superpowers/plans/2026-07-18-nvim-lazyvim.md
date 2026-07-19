# nvim (LazyVim) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a LazyVim-based `~/.config/nvim` as a new stow package, with LSP/treesitter/formatting for TypeScript/JS, Python, Rust, JSON, YAML, Docker, and Shell, verified end-to-end.

**Architecture:** Plain LazyVim starter (no fork, no custom installer) landed at `nvim/.config/nvim/` in the dotfiles repo as a stow package. Customization happens exclusively through additive files under `lua/plugins/` — never by editing LazyVim's own core. Language support comes from LazyVim's official per-language "extras" (one-line imports) plus one small hand-written file for the one gap extras don't cover (bash/shell LSP) and one gap the Rust extra assumes but this machine lacks (a `rustup`-installed `rust-analyzer`).

**Tech Stack:** Neovim 0.12.4, `lazy.nvim` (plugin manager), `mason.nvim` (LSP/tool installer), `nvim-lspconfig`, `nvim-treesitter`, `conform.nvim` (formatting) — all provided transitively by LazyVim. Verified against LazyVim's live source (`LazyVim/LazyVim`, `LazyVim/starter` on GitHub) during planning, not assumed from memory.

## Global Constraints

- New stow package `nvim`, contents mirroring `$HOME`: `nvim/.config/nvim/...`. Added to the `Makefile`'s `PACKAGES` list.
- Theme: LazyVim's default (tokyonight) — do not set `colorscheme` anywhere.
- Do not add DAP/debugging config, test-runner (neotest) config, session/project management, or AI-in-editor plugins. (Some language extras pull in `optional = true` DAP/test dependencies that silently no-op unless their base plugin is also present — that's fine and expected; do not add the base plugins that would activate them.)
- Do not modify `scripts/.local/bin/nvim-at-line`, `scripts/.local/bin/thumbs-open`, or `scripts/.local/bin/tmux-goto` — they already invoke `nvim`/`nvim +N -- file` correctly.
- Do not modify `git/.gitconfig` or `zsh/.aliases` — `core.editor = nvim` and `alias vim='nvim'` are already correct.
- Work on a feature branch; never push without being asked (repo convention, `~/.dotfiles/CLAUDE.md`).
- No secrets in any created file (none needed for this work).

---

## File Structure

| File | Responsibility |
|---|---|
| `nvim/.config/nvim/init.lua` | LazyVim bootstrap entrypoint (verbatim from `LazyVim/starter`) |
| `nvim/.config/nvim/lua/config/lazy.lua` | `lazy.nvim` setup: clones itself, imports LazyVim core + your `plugins/` dir |
| `nvim/.config/nvim/lua/config/autocmds.lua` | Empty template for custom autocmds (starter default) |
| `nvim/.config/nvim/lua/config/keymaps.lua` | Empty template for custom keymaps (starter default) |
| `nvim/.config/nvim/lua/config/options.lua` | Empty template for custom options (starter default) |
| `nvim/.config/nvim/lua/plugins/example.lua` | Disabled reference file showing the plugin-spec patterns (starter default) |
| `nvim/.config/nvim/lua/plugins/lang-extras.lua` | Enables the 6 official language extras + hand-wires bash LSP + `rust-analyzer` via mason (NEW, Task 2) |
| `nvim/.config/nvim/.neoconf.json` | `lua_ls`/neodev settings for editing the config itself (starter default) |
| `nvim/.config/nvim/stylua.toml` | Lua formatting style for the config itself (starter default) |
| `Makefile` | Add `nvim` to `PACKAGES` (MODIFY) |

---

## Task 1: Bootstrap the LazyVim starter as a stow package

**Files:**
- Create: `nvim/.config/nvim/init.lua`
- Create: `nvim/.config/nvim/lua/config/lazy.lua`
- Create: `nvim/.config/nvim/lua/config/autocmds.lua`
- Create: `nvim/.config/nvim/lua/config/keymaps.lua`
- Create: `nvim/.config/nvim/lua/config/options.lua`
- Create: `nvim/.config/nvim/lua/plugins/example.lua`
- Create: `nvim/.config/nvim/.neoconf.json`
- Create: `nvim/.config/nvim/stylua.toml`
- Modify: `Makefile:5` (the `PACKAGES` line)

**Interfaces:**
- Consumes: nothing (first task).
- Produces: a working `~/.config/nvim` symlinked into the repo, with LazyVim core installed under `~/.local/share/nvim/lazy/`. Task 2 adds files into the same `nvim/.config/nvim/lua/plugins/` directory this task creates. Task 3 verifies the result of both.

- [ ] **Step 1: Failing test (confirm current state)**

```bash
test -e ~/.config/nvim && echo "EXISTS (unexpected)" || echo "MISSING (expected)"
grep -qE '^PACKAGES := .*\bnvim\b' ~/.dotfiles/Makefile && echo "present (unexpected)" || echo "absent (expected)"
```
Expected: `MISSING (expected)` and `absent (expected)`.

- [ ] **Step 2: Create the starter files**

`nvim/.config/nvim/init.lua`:
```lua
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
```

`nvim/.config/nvim/lua/config/lazy.lua`:
```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
```

`nvim/.config/nvim/lua/config/autocmds.lua`:
```lua
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
```

`nvim/.config/nvim/lua/config/keymaps.lua`:
```lua
-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
```

`nvim/.config/nvim/lua/config/options.lua`:
```lua
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
```

`nvim/.config/nvim/lua/plugins/example.lua`:
```lua
-- since this is just an example spec, don't actually load anything here and return an empty spec
-- stylua: ignore
if true then return {} end

-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },

  -- change trouble config
  {
    "folke/trouble.nvim",
    -- opts will be merged with the parent spec
    opts = { use_diagnostic_signs = true },
  },

  -- disable trouble
  { "folke/trouble.nvim", enabled = false },

  -- override nvim-cmp and add cmp-emoji
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      table.insert(opts.sources, { name = "emoji" })
    end,
  },

  -- change some telescope options and a keymap to browse plugin files
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- add a keymap to browse plugin files
      -- stylua: ignore
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
    },
    -- change some options
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },

  -- add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        pyright = {},
      },
    },
  },

  -- add tsserver and setup with typescript.nvim instead of lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "jose-elias-alvarez/typescript.nvim",
      init = function()
        require("lazyvim.util").lsp.on_attach(function(_, buffer)
          -- stylua: ignore
          vim.keymap.set( "n", "<leader>co", "TypescriptOrganizeImports", { buffer = buffer, desc = "Organize Imports" })
          vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
        end)
      end,
    },
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- tsserver will be automatically installed with mason and loaded with lspconfig
        tsserver = {},
      },
      -- you can do any additional lsp server setup here
      -- return true if you don't want this server to be setup with lspconfig
      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      setup = {
        -- example to setup with typescript.nvim
        tsserver = function(_, opts)
          require("typescript").setup({ server = opts })
          return true
        end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
      },
    },
  },

  -- for typescript, LazyVim also includes extra specs to properly setup lspconfig,
  -- treesitter, mason and typescript.nvim. So instead of the above, you can use:
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },

  -- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
  -- would overwrite `ensure_installed` with the new value.
  -- If you'd rather extend the default config, use the code below instead:
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- add tsx and treesitter
      vim.list_extend(opts.ensure_installed, {
        "tsx",
        "typescript",
      })
    end,
  },

  -- the opts function can also be used to change the default opts:
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, {
        function()
          return "😄"
        end,
      })
    end,
  },

  -- or you can return new options to override all the defaults
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      return {
        --[[add your custom lualine config here]]
      }
    end,
  },

  -- use mini.starter instead of alpha
  { import = "lazyvim.plugins.extras.ui.mini-starter" },

  -- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc
  { import = "lazyvim.plugins.extras.lang.json" },

  -- add any tools you want to have installed below
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
      },
    },
  },
}
```

`nvim/.config/nvim/.neoconf.json`:
```json
{
  "neodev": {
    "library": {
      "enabled": true,
      "plugins": true
    }
  },
  "neoconf": {
    "plugins": {
      "lua_ls": {
        "enabled": true
      }
    }
  }
}
```

`nvim/.config/nvim/stylua.toml`:
```toml
indent_type = "Spaces"
indent_width = 2
column_width = 120
```

- [ ] **Step 3: Add the package to the Makefile**

In `~/.dotfiles/Makefile`, change:
```makefile
PACKAGES := zsh git ghostty cursor lazygit atuin tmux scripts
```
to:
```makefile
PACKAGES := zsh git ghostty cursor lazygit atuin tmux scripts nvim
```

- [ ] **Step 4: Link the package and verify no conflicts**

```bash
cd ~/.dotfiles
make status
make link
test -L ~/.config/nvim && readlink -f ~/.config/nvim
```
Expected: `make status` shows no conflicts for `nvim`; `readlink -f` prints `/home/dima/.dotfiles/nvim/.config/nvim`.

- [ ] **Step 5: Bootstrap plugins (first headless sync)**

```bash
timeout 300 nvim --headless "+Lazy! sync" +qa
echo "exit=$?"
```
Expected: `exit=0`, no `Error` lines in the output above it.

- [ ] **Step 6: Verify plugins actually installed**

```bash
test -d ~/.local/share/nvim/lazy/LazyVim && echo "LazyVim core: OK"
test -d ~/.local/share/nvim/lazy/tokyonight.nvim && echo "tokyonight: OK"
test -f ~/.config/nvim/lazy-lock.json && echo "lazy-lock.json: OK"
```
Expected: all three print `OK`.

- [ ] **Step 7: Commit**

```bash
cd ~/.dotfiles
git add nvim/.config/nvim Makefile
git commit -m "feat(nvim): bootstrap LazyVim as a new stow package"
```

---

## Task 2: Enable language support (TypeScript, Python, Rust, JSON, YAML, Docker, Shell)

**Files:**
- Create: `nvim/.config/nvim/lua/plugins/lang-extras.lua`

**Interfaces:**
- Consumes: the `nvim/.config/nvim/lua/plugins/` directory and working LazyVim install from Task 1.
- Produces: the enabled language spec that Task 3 exercises per-language.

- [ ] **Step 1: Failing test (confirm current state)**

```bash
test -e ~/.dotfiles/nvim/.config/nvim/lua/plugins/lang-extras.lua && echo "EXISTS (unexpected)" || echo "MISSING (expected)"
test -d ~/.local/share/nvim/lazy/rustaceanvim && echo "present (unexpected)" || echo "absent (expected)"
```
Expected: both `MISSING (expected)` / `absent (expected)`.

- [ ] **Step 2: Create the language extras file**

`nvim/.config/nvim/lua/plugins/lang-extras.lua`:
```lua
return {
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
  { import = "lazyvim.plugins.extras.lang.docker" },

  -- prettier for JS/TS/JSON/YAML/CSS/HTML/Markdown format-on-save, respecting
  -- a project's own .prettierrc when present; without this, TypeScript files
  -- only get vtsls's own LSP-fallback formatting, which ignores prettier
  -- config -- not what "format-on-save for TypeScript/Node-heavy work" means
  { import = "lazyvim.plugins.extras.formatting.prettier" },

  -- LazyVim has no official bash/shell extra; treesitter's "bash" parser and
  -- conform's "shfmt" formatter are already in LazyVim's core defaults, so
  -- only the LSP server needs adding here
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
      },
    },
  },

  -- the rust extra expects rustup to already provide rust-analyzer and
  -- doesn't install it itself; this machine has no rust toolchain, so pull
  -- it from mason explicitly
  {
    "mason.nvim",
    opts = {
      ensure_installed = { "rust-analyzer" },
    },
  },
}
```

- [ ] **Step 3: Re-sync plugins**

```bash
timeout 300 nvim --headless "+Lazy! sync" +qa
echo "exit=$?"
```
Expected: `exit=0`, no `Error` lines.

- [ ] **Step 4: Verify the new plugins were picked up**

```bash
test -d ~/.local/share/nvim/lazy/rustaceanvim && echo "rustaceanvim: OK"
test -d ~/.local/share/nvim/lazy/SchemaStore.nvim && echo "SchemaStore.nvim: OK"
test -d ~/.local/share/nvim/lazy/crates.nvim && echo "crates.nvim: OK"
```
Expected: all three print `OK` (these are only pulled in by the rust/json/yaml extras — their presence proves the extras loaded).

- [ ] **Step 5: Commit**

```bash
cd ~/.dotfiles
git add nvim/.config/nvim/lua/plugins/lang-extras.lua
git commit -m "feat(nvim): enable LSP for TypeScript, Python, Rust, JSON, YAML, Docker, and Shell"
```

---

## Task 3: Verify LSP, formatting, and popup integration end-to-end

**Files:**
- None created or modified — this task only verifies the result of Tasks 1–2 against the spec's success criteria.

**Interfaces:**
- Consumes: the working `nvim/.config/nvim` from Task 1 and the language extras from Task 2.
- Produces: nothing further downstream — this is the plan's final task.

- [ ] **Step 1: Write the LSP-attach checker**

```bash
mkdir -p /tmp/nvim-lazyvim-verify
cat > /tmp/nvim-lazyvim-verify/checker.lua <<'LUA'
local expected = os.getenv("LSP_CHECK_EXPECT")
local outfile = os.getenv("LSP_CHECK_OUT")
local ok = vim.wait(60000, function()
  return #vim.lsp.get_clients({ bufnr = 0 }) > 0
end, 300)
local names = {}
for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
  table.insert(names, c.name)
end
local joined = table.concat(names, ",")
local found = false
for _, n in ipairs(names) do
  if n:lower():find(expected:lower(), 1, true) then
    found = true
  end
end
local f = io.open(outfile, "w")
f:write((found and "PASS" or "FAIL") .. " clients=" .. joined .. "\n")
f:close()
vim.cmd("qa!")
LUA
```

- [ ] **Step 2: Run it once per language**

```bash
V=/tmp/nvim-lazyvim-verify
CHECKER="$V/checker.lua"

# TypeScript
mkdir -p "$V/ts" && cd "$V/ts"
echo '{}' > package.json
printf 'const x: number = 1;\nconsole.log(x);\n' > sample.ts
LSP_CHECK_EXPECT="vtsls" LSP_CHECK_OUT="$V/ts.result" nvim --headless -- sample.ts -c "luafile $CHECKER"
cat "$V/ts.result"

# Python
mkdir -p "$V/py" && cd "$V/py"
printf '[project]\nname = "sample"\nversion = "0.1.0"\n' > pyproject.toml
printf 'x: int = 1\nprint(x)\n' > sample.py
LSP_CHECK_EXPECT="pyright" LSP_CHECK_OUT="$V/py.result" nvim --headless -- sample.py -c "luafile $CHECKER"
cat "$V/py.result"

# Rust
mkdir -p "$V/rs" && cd "$V/rs"
printf '[package]\nname = "sample"\nversion = "0.1.0"\n' > Cargo.toml
printf 'fn main() {\n    println!("hi");\n}\n' > sample.rs
LSP_CHECK_EXPECT="rust" LSP_CHECK_OUT="$V/rs.result" nvim --headless -- sample.rs -c "luafile $CHECKER"
cat "$V/rs.result"

# JSON
mkdir -p "$V/json" && cd "$V/json"
printf '{}\n' > sample.json
LSP_CHECK_EXPECT="jsonls" LSP_CHECK_OUT="$V/json.result" nvim --headless -- sample.json -c "luafile $CHECKER"
cat "$V/json.result"

# YAML
mkdir -p "$V/yaml" && cd "$V/yaml"
printf 'key: value\n' > sample.yaml
LSP_CHECK_EXPECT="yamlls" LSP_CHECK_OUT="$V/yaml.result" nvim --headless -- sample.yaml -c "luafile $CHECKER"
cat "$V/yaml.result"

# Docker
mkdir -p "$V/docker" && cd "$V/docker"
printf 'FROM alpine:latest\n' > Dockerfile
LSP_CHECK_EXPECT="dockerls" LSP_CHECK_OUT="$V/docker.result" nvim --headless -- Dockerfile -c "luafile $CHECKER"
cat "$V/docker.result"

# Shell
mkdir -p "$V/sh" && cd "$V/sh"
printf '#!/usr/bin/env bash\necho hi\n' > sample.sh
LSP_CHECK_EXPECT="bashls" LSP_CHECK_OUT="$V/sh.result" nvim --headless -- sample.sh -c "luafile $CHECKER"
cat "$V/sh.result"
```
Expected: every `*.result` file starts with `PASS`. If any prints `FAIL` or `TIMEOUT`, the `clients=` list shows what (if anything) actually attached — use that to debug before moving on; do not proceed to Step 3 with a failing language.

- [ ] **Step 3: Verify format-on-save (prettier on a `.ts` file, per the spec's own example)**

```bash
V=/tmp/nvim-lazyvim-verify
mkdir -p "$V/fmt" && cd "$V/fmt"
echo '{}' > package.json
cat > messy.ts <<'SCRIPT'
const   x='hello'
console.log(x)
SCRIPT
before=$(cat messy.ts)
nvim --headless -- messy.ts -c "sleep 2" -c "write" -c "qa!"
after=$(cat messy.ts)
if [[ "$before" != "$after" ]] && [[ "$after" == *'"hello"'* ]]; then
  echo "PASS: prettier reformatted single quotes to double quotes on save"
  echo "$after"
else
  echo "FAIL: file unchanged, or not prettier-shaped"
  echo "$after"
fi
```
Expected: `PASS: prettier reformatted single quotes to double quotes on save`, with output showing `const x = "hello";` (double-quoted, semicolon added) — prettier's default style, not vtsls's.

- [ ] **Step 4: Regression-check the git editor and `vim` alias (must be unaffected)**

```bash
git config --get core.editor
zsh -i -c "alias vim" 2>&1
```
Expected: `nvim`, and `vim='nvim'`.

- [ ] **Step 5: Manual check — popup UI and icons**

This part can't be scripted headlessly (it's about what actually renders on screen). In a live tmux pane:
- `prefix + f` (tmux-goto) to a file, or trigger `thumbs-open`/`extrakto` on visible text — confirm the popup shows LazyVim's full UI (statusline, correct syntax highlighting, file-type icons rendering as glyphs, not boxes).
- Open one file per language covered above and confirm diagnostics/completion visibly work (e.g. type an obvious type error in the `.ts` fixture and see a diagnostic squiggle).

- [ ] **Step 6: Clean up the verification scratch directory**

```bash
rm -rf /tmp/nvim-lazyvim-verify
```

- [ ] **Step 7: Commit (if Step 5's manual check prompted any config tweak; otherwise skip — this task changes no files by default)**

---

## Self-Review Notes

- **Spec coverage:** distro + stow package ✅ (Task 1), all 6 language extras ✅ (Task 2), bash/shell gap ✅ (Task 2, hand-wired), theme default ✅ (Global Constraints — untouched `install.colorscheme` default, no override), popup dashboard non-issue ✅ (inherent — all fixtures pass a file argument, same as the real popup scripts), format-on-save ✅ (Task 3 Step 3, using the spec's own literal example), LSP per language ✅ (Task 3 Step 2), UI/icons ✅ (Task 3 Step 5, manual — genuinely can't be scripted), git editor/vim alias unaffected ✅ (Task 3 Step 4), YAGNI exclusions ✅ (Global Constraints, explicitly listed as "do not add").
- **Verified against live source, not memory:** every file in Task 1 and every extra name in Task 2 was fetched directly from `LazyVim/starter` and `LazyVim/LazyVim` on GitHub during planning (see conversation). Two genuine gaps surfaced this way, both handled explicitly rather than silently left broken: (1) the Rust extra assumes `rustup`, but this machine has neither `rustup` nor `cargo`, so `rust-analyzer` is pulled from mason directly; (2) the TypeScript extra's default backend (`vtsls`) bundles no formatter, so a `.ts` file would only get LSP-fallback formatting that ignores a project's `.prettierrc` — the dedicated `formatting.prettier` extra is added so format-on-save actually behaves like real-world TypeScript/Node tooling expects.
- **Placeholder scan:** none found — every step has literal file content or a literal, runnable command with a stated expected output.
- **Known minor side effects, accepted rather than fought:** enabling the `rust` extra installs `codelldb` (a DAP adapter binary) via mason as a side effect of `mason-org/mason.nvim`'s `optional = true` hook, even though DAP itself isn't enabled; enabling the `docker` extra similarly installs `hadolint` even though no linter plugin is enabled to use it. Both are inert unused binaries on disk, not active features — not worth the complexity of suppressing.
- **Type/name consistency:** `lang-extras.lua`'s plugin target strings (`"neovim/nvim-lspconfig"`, `"mason.nvim"`) match the exact identifiers used by LazyVim's own official extras (verified in `docker.lua`), so they merge correctly with the rest of LazyVim's spec rather than creating a duplicate/conflicting plugin entry.
