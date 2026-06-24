# Dotfiles

Personal configuration files for Linux and macOS, managed with GNU stow — simple, transparent, and under control.

## Philosophy

Managed with GNU stow: configs live in topic packages under `~/.dotfiles`, and
stow symlinks them into `$HOME`. Simple and transparent — symlinks, no rendering
magic — with a `Makefile` so day-to-day management is one command.

## Structure

```
~/.dotfiles/
├── Makefile          # stow management layer
├── CLAUDE.md         # conventions for AI sessions
├── README.md
├── zsh/              # → ~/.zshrc, ~/.aliases, ~/.zshrc.linux, ~/.zshrc.macos
├── git/              # → ~/.gitconfig
├── ghostty/          # → ~/.config/ghostty/config
└── cursor/           # → ~/.config/Cursor/User/settings.json
```

## Installation

```bash
git clone git@github.com:dimaskh/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make link        # symlinks every package into $HOME
```

Machine-specific or private shell config (e.g. work aliases) goes in
`~/.zshrc.local`, which is gitignored and sourced by `.zshrc`.

## Usage

| Command | Action |
|---------|--------|
| `make link` | Symlink all packages into `$HOME` |
| `make unlink` | Remove all symlinks |
| `make restow` | Re-link (after adding files) |
| `make status` | Show what stow would change |
| `make add pkg=<p> path=<file>` | Bring a live file under management |

## Tools Used

- **Shell**: Zsh with Oh My Zsh
- **Prompt**: Starship
- **Navigation**: Zoxide
- **Terminal**: Tmux + Tmuxinator
- **Editor**: Neovim, Cursor
- **Package Manager**: NVM, Pacman (Arch), Homebrew (macOS)

## Aliases

### General
- `vim` → nvim
- `mkcd` → mkdir && cd
- `reload` → source ~/.zshrc
- `myip` → show public IP

### Git
- `gcm` → git commit -m
- `gac` → git add . && git commit -a -m
- `gpu` → git push upstream
- `glu` → git pull upstream

### Tmux
- `t` → tmux
- `ta` → tmux attach -t
- `tls` → tmux ls
- `tns` → tmux new -s
- `tx` → tmuxinator

### Pacman (Arch Linux)
- `update`/`upd` → sudo pacman -Syyu
- `sps` → sudo pacman -S
- `spr` → sudo pacman -R
- `sprs` → sudo pacman -Rs
- `sprdd` → sudo pacman -Rdd
- `spqo` → sudo pacman -Qo
- `spsii` → sudo pacman -Sii

## Platform-Specific Notes

### Linux (Arch)
- SSH agent configured with KDE's ksshaskpass
- NVM loaded from `/usr/share/nvm/init-nvm.sh`
- LM Studio added to PATH
- Pacman aliases available

### macOS
- NVM loaded from Homebrew path
- Homebrew for package management

## Configuration Details

### Git
- Default branch: `main`
- Editor: nvim
- SSH preference over HTTPS for GitHub

### Cursor/VS Code
- Font: FiraCode Nerd Font Mono
- Theme: GitHub Dark
- Format on save: enabled
- Biome formatter for JS/TS
- Black formatter for Python

## Future Additions

These are recommended tools and configurations to consider adding as you expand your setup:

### Terminal & Shell
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder for command line
- [bat](https://github.com/sharkdp/bat) - Cat clone with syntax highlighting and git integration
- [eza](https://github.com/eza-community/eza) - Modern ls replacement with colors and icons
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Fast grep alternative written in Rust
- [exa/eza aliases](https://github.com/eza-community/eza) - Enhanced `ls` commands

### Development Tools
- **Neovim config** (`nvim/`) - Lua-based Neovim configuration
- **Tmux config** (`tmux.conf`) - Tmux settings, keybindings, and plugins
- **Package lists** - `Brewfile` (macOS), `pacman-packages.txt` (Arch) for reproducibility
- **GitHub CLI** - gh configuration for GitHub integration

### System & Utilities
- **Systemd user services** - Custom services for background tasks
- **Cron jobs** - Automated maintenance and backup tasks
- **Scripts directory** - Helper scripts for common operations
- **Makefile** - Common maintenance tasks (update, clean, backup)

### Additional Configuration
- **Starship config** (`starship.toml`) - Customize starship prompt
- **Tmuxinator** (`tmuxinator/`) - Project-specific tmux sessions
- **SSH config** - Host aliases and connection settings
- **YAML configs** - For any tools that support it

### Quality of Life
- **.gitignore** - Already included for sensitive/machine-specific files
- **LICENSE** - MIT or other open source license
- **Directory structure** - Organize by tool or by system
- **Changelog** - Track changes over time

## Workflow

1. Edit config files **in the repo** (`~/.dotfiles/<package>/...`) — the live path is a symlink.
2. `make restow` if you added new files to a package.
3. Commit and push when ready (never push without being asked on a shared machine).
4. To bring a new live file under management: `make add pkg=<package> path=<file>`.

## License

MIT
