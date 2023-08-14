#!/bin/bash

echo "Apply dotfiles configuration"

echo "Apply aliases"
cp .aliases ~

echo "Apply tmux"
cp .tmux.conf ~
