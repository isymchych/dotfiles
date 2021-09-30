#!/usr/bin/env bash

# install Vundle
git clone https://github.com/VundleVim/Vundle.vim.git ./.vim/bundle/Vundle.vim

# run vim and install plugins using Vundle
vim +PluginInstall +qall
