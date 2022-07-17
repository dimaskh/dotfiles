# Path to oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

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
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Default editor
export EDITOR='nvim'

# Starship
eval "$(starship init zsh)"

# SSH Agent
# eval "$(ssh-agent -s)" &> /dev/null
# export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

if [ ! -S ~/.ssh/ssh_auth_sock ]; then
  eval `ssh-agent`
  ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
fi
export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
# ssh-add -l > /dev/null || ssh-add ~/.ssh/id_ed25519 ~/.ssh/id_ed25519_github

# eval `keychain --agents ssh --eval id_ed25519 id_ed25519_github`

# source ~/.ssh/agent_out &> /dev/null
# if ! ps -p $SSH_AGENT_PID &> /dev/null
# then
#   ssh-agent > ~/.ssh/agent_out
#   source ~/ssh/agent_out &> /dev/null
# fi

# if [ ! -S ~/.ssh/ssh_auth_sock ]; then
#     echo "'ssh-agent' has not been started since the last reboot." \
#          "Starting 'ssh-agent' now."
#     eval "$(ssh-agent -s)"
#     ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
# fi
# export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
# # see if any key files are already added to the ssh-agent, and if not, add them
# ssh-add -l > /dev/null
# if [ "$?" -ne "0" ]; then
#     echo "No ssh keys have been added to your 'ssh-agent' since the last" \
#          "reboot. Adding default keys now."
#     ssh-add
# fi
# export SSH_ASKPASS='/usr/bin/ksshaskpass'
# Fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
