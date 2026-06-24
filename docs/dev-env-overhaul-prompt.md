# Dev-environment overhaul — Claude Code kickoff prompt

Paste the block below into a fresh Claude Code conversation opened in `~/.dotfiles`
(or `~`) to start the terminal-first / dotfiles overhaul. It's self-contained —
the new session won't have prior context.

Created 2026-06-22 alongside the TrackGuard cross-repo workflow setup (the
`umcp/mios/rsrch/tg-hub/tg` aliases referenced below live in a managed block in
`~/.zshrc`).

---

```
I want to migrate from running Claude Code inside the VS Code extension to a
terminal-first workflow, and as part of that, overhaul my whole Arch Linux dev
environment so the terminal is a first-class place to work and to run multiple
Claude Code sessions in parallel.

Start by using the brainstorming skill — interview me on priorities, aesthetics,
and how much churn I'll tolerate BEFORE changing anything. Don't touch configs
until we've agreed a plan. Work incrementally, back up every file before editing,
and never break my currently-working setup in a single step.

## My current environment (audit and confirm these first)
- OS: Arch Linux, rolling. Shell: zsh via oh-my-zsh.
- Prompt: starship. Dir-jump: zoxide. Node: nvm (currently v24.14.1).
- zsh plugins: archlinux, git, docker, docker-compose, sudo,
  zsh-autosuggestions, zsh-syntax-highlighting.
- ~/.zshrc sources ~/.aliases. Terminal: ghostty. Editor (terminal): nvim.
- GUI editors present: VSCodium, Cursor, VS Code.
- Existing dotfiles repo at ~/.dotfiles (git@github.com:dimaskh/dotfiles.git) with
  zsh/, git/, cursor/ dirs — but my live ~/.zshrc is NOT yet symlinked into it,
  so the repo isn't actually managing my configs yet. Fixing that is in scope.
- No terminal multiplexer yet — I want to choose one.
- IMPORTANT: ~/.zshrc contains a managed block delimited by
  "# === TrackGuard / Eruptr Claude Code workspaces" … "# === End TrackGuard
  workspaces block ===" with aliases (umcp/mios/rsrch/tg-hub/tg). Preserve it
  verbatim; it's part of a separate active workflow.

## Goals
1. Dotfiles management — recommend and set up a strategy (chezmoi vs GNU stow vs
   bare git repo), with tradeoffs, then migrate my existing configs into
   ~/.dotfiles and symlink/manage the live files.
2. ghostty — a clean, fast config: theme, nerd font, keybindings, padding,
   shell integration, scrollback.
3. zsh — review prompt/plugins/completion/history/keybindings; decide whether to
   stay on oh-my-zsh or move to a lighter setup (zinit/z4h/antidote); organize
   ~/.aliases sensibly.
4. nvim — decide between a curated base (kickstart.nvim / LazyVim / AstroNvim) or
   a custom config, set it up as a genuinely usable editor (LSP, treesitter,
   telescope/fzf, git, format-on-save) for TypeScript/Node-heavy work.
5. Terminal multiplexer — decide tmux vs zellij, weighted heavily toward running
   and switching between MULTIPLE concurrent Claude Code sessions across 4
   project directories (this is the main use case). Set up sane keybindings,
   session persistence, and a layout/launcher for the project switching.
6. Modern CLI tooling — recommend and install a coherent set (ripgrep, fd, bat,
   eza, fzf, zoxide, delta, lazygit, etc.) and wire them into zsh/nvim/git.
7. Terminal-first Claude Code ergonomics — statusline, /fast, keybindings,
   session resume/continue, notifications, and a multiplexer-based pattern for
   keeping the 4 workspaces one keystroke apart. (I have the superpowers,
   caveman, and claude-mem plugins installed.)

## Constraints
- Arch Linux, zsh, ghostty are fixed. Everything else is open to change.
- Keep it fast and low-bloat; I value snappiness over maximalism.
- Show me tradeoffs and let me choose at each decision point; recommend a default.
- Reversible changes only; commit dotfiles to version control as we go.
```
