# Dotfiles

Personal configuration files for Linux and macOS. Deliberately managed as a plain Git repository with manual symlinking - simple, transparent, and under control.

## Philosophy

This repo uses a simple approach: clone the repository, then symlink only the configuration files you actually need. No automation, no magic - just intentional control over what goes where.

## Structure

```
~/.dotfiles/
├── zsh/              # Zsh shell configurations
│   ├── .zshrc       # Main Zsh config
│   ├── .aliases     # Shell aliases
│   ├── .zshrc.linux # Linux-specific config
│   └── .zshrc.macos # macOS-specific config
├── git/
│   └── .gitconfig   # Git configuration
└── cursor/
    └── settings.json # Cursor/VS Code settings
```

## Installation

1. Clone the repository:
   ```bash
   git clone git@github.com:dima-skhl/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Symlink configuration files as needed:
   ```bash
   # Zsh
   ln -s ~/.dotfiles/zsh/.zshrc ~/.zshrc
   ln -s ~/.dotfiles/zsh/.aliases ~/.aliases
   ln -s ~/.dotfiles/zsh/.zshrc.linux ~/.zshrc.linux  # Arch only
   ln -s ~/.dotfiles/zsh/.zshrc.macos ~/.zshrc.macos  # macOS only
   
   # Git
   ln -s ~/.dotfiles/git/.gitconfig ~/.gitconfig
   
   # Cursor
   mkdir -p ~/.config/Cursor/User
   ln -s ~/.dotfiles/cursor/settings.json ~/.config/Cursor/User/settings.json
   ```

3. Install dependencies:
   - **Zsh**: Install [Oh My Zsh](https://ohmyz.sh/), [Starship](https://starship.rs/), [Zoxide](https://github.com/ajeetdsouza/zoxide)
   - **Zsh Plugins**: `zsh-autosuggestions`, `zsh-syntax-highlighting`
   - **Tmux**: Install Tmux and Tmuxinator
   - **NVM**: Install [nvm](https://github.com/nvm-sh/nvm)

4. Reload your shell:
   ```bash
   source ~/.zshrc
   ```

## Multi-Computer Setup

This repo supports both Arch Linux and macOS:

### Arch Linux
```bash
ln -s ~/.dotfiles/zsh/.zshrc.linux ~/.zshrc.linux
```

### macOS
```bash
ln -s ~/.dotfiles/zsh/.zshrc.macos ~/.zshrc.macos
```

Each computer only symlinks what it needs - shared configs go in the main files, platform-specific in their respective files.

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

1. Make changes to your config files
2. Push to repository: `git add . && git commit -m "message" && git push`
3. On other computers: `git pull` to update
4. Symlink new files only when you're ready

## License

MIT
