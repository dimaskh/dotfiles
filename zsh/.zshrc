# Aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Prompt
eval "$(starship init zsh)"

# Navigation
eval "$(zoxide init zsh)"

# OS-specific
case "$(uname -s)" in
  Linux)  [[ -f ~/.zshrc.linux ]] && source ~/.zshrc.linux ;;
  Darwin) [[ -f ~/.zshrc.macos ]] && source ~/.zshrc.macos ;;
esac
