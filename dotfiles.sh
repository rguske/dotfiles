#!/bin/bash
# copy ZSH config files into Git dir dotfiles

set -euo pipefail

cp -R $HOME/.zshrc $HOME/.zsh_aliases $HOME/dotfiles.sh $DOTFILESDIR

cd $DOTFILESDIR

ls -rtla

git status

git add .

git commit -s -m "backup ${DATE}"

gloga

cd $HOME
