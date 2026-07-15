# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=(archlinux git docker docker-compose sudo zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Aliases (sourced AFTER OMZ so our eza/modern aliases override OMZ's ls/ll/la/l defaults)
[[ -f ~/.aliases ]] && source ~/.aliases

# tmux workspace helpers (tmux_workspace, ws) — used by the private per-project workspace aliases in ~/.zshrc.local
[[ -f ~/.functions ]] && source ~/.functions

# Prompt
eval "$(starship init zsh)"

# Navigation
eval "$(zoxide init zsh)"

# fzf (fd-backed, bat preview) — owns Ctrl-T (files) and Alt-C (cd)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border \
  --preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null || eza --tree --color=always {}'"
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

# bat as man pager
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# yazi: quit into the last directory
y() {
	local tmp; tmp="$(mktemp -t yazi-cwd.XXXXXX)"
	yazi "$@" --cwd-file="$tmp"
	local cwd; cwd="$(command cat -- "$tmp")"
	[[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# atuin — owns Ctrl-R + Up. Evaluated LAST (before OS blocks) so it wins the keybindings.
command -v atuin >/dev/null && eval "$(atuin init zsh)"

# OS-specific
case "$(uname -s)" in
  Linux)  [[ -f ~/.zshrc.linux ]] && source ~/.zshrc.linux ;;
  Darwin) [[ -f ~/.zshrc.macos ]] && source ~/.zshrc.macos ;;
esac

# Machine-specific / private overrides (not version-controlled)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
