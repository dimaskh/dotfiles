#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

export PATH="$HOME/.local/bin:$PATH"

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec startx
fi
. "$HOME/.cargo/env"

export TASKRC=~/.config/taskwarrior/.taskrc
export TASKDATA=~/.config/taskwarrior/.task
