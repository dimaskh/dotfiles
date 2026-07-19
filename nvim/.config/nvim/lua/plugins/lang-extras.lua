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
