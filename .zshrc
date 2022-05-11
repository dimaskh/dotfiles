# Path to your oh-my-zsh installation.
export ZSH="/Users/dhurk/.oh-my-zsh"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  docker
  docker-compose
  zsh-syntax-highlighting
  zsh-autosuggestions
)

# Source oh-my-zsh script
source $ZSH/oh-my-zsh.sh

# Custom aliases
source ~/.aliases

# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Default editor
export EDITOR='nvim'

# Starship
eval "$(starship init zsh)"
