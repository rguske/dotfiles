#!/bin/bash
# copy ZSH config files into Git dir dotfiles
cp ~/.zshrc ~/.zsh_aliases ~/dotfiles.sh '$DOTFILESDIR'

ls -rtla '$DOTFILESDIR'

cd '$DOTFILESDIR'

git status

git add .

git commit -s -m "backup $date"

gloga

cd '$HOME'
