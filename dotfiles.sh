#!/bin/bash
# copy ZSH config files into Git dir dotfiles
cp -r ~/.zshrc ~/.zsh_aliases ~/dotfiles.sh ${DOTFILESDIR}

ls -rtla ${DOTFILESDIR}

cd ${DOTFILESDIR}

git status

git add .

git commit -s -m "backup ${DATE}"

gloga

cd ${HOME}
