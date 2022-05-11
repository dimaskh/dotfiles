git clone --bare git@github.com:dimaskh/dotfiles.git $HOME/.dotfiles

function dotfiles {
  /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}

mkdir -p .dotfiles-backup

dotfiles checkout

if [ $? = 0 ]; then
  echo "Updated dotfiles";
  else
    echo "Backing up pre-existing dotfiles.";
    dotfiles checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .dotfiles-backup/{}
fi;

dotfiles checkout

dotfiles config --local status.showUntrackedFiles no
dotfiles config --local user.name "dimaskh"
dotfiles config --local user.email "dimaskh.dev@gmail.com"
