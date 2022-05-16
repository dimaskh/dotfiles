# My dotfiles

This repository contains my personal dotfiles.  They are stored here for convenience so that I may quickly access them on new machines or new installs.  Also, others may find some of my configurations helpful in customizing their own dotfiles.

## Requirements

- Git

## How To Manage Dotfiles

I use the git bare repository method for managing my dotfiles. Here is an article about this method of managing your dotfiles: https://developer.atlassian.com/blog/2016/02/best-way-to-store-dotfiles-git-bare-repo/

## Installation On The New Machine

    git clone --bare git@github.com:dimaskh/dotfiles.git $HOME/.dotfiles
    alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
    dotfiles config --local status.showUntrackedFiles no
    dotfiles checkout
