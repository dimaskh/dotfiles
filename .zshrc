# Path to oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Plugins
plugins=(
  git
  docker
  docker-compose
  sudo
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Source oh-my-zsh script
source $ZSH/oh-my-zsh.sh

# Custom aliases
source ~/.aliases

# NVM
source /usr/share/nvm/init-nvm.sh

# Default editor
export EDITOR='nvim'

# Starship
eval "$(starship init zsh)"

# SSH Agent
# eval "$(ssh-agent -s)" &> /dev/null
# if ! pgrep -u "$USER" ssh-agent > /dev/null; then
#     ssh-agent -t 12h > "$XDG_RUNTIME_DIR/ssh-agent.env"
# fi
# if [[ ! -f "$SSH_AUTH_SOCK" ]]; then
#     source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
# fi
export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket

# Fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Path
# export PATH="$HOME/.local/bin:$PATH"

# Taskwarrior
export TASKRC=~/.config/taskwarrior/.taskrc
export TASKDATA=~/.config/taskwarrior/.task

