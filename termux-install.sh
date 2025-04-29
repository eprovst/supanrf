#!/bin/bash
yes | pkg upgrade
yes | pkg install git make rust
if [ ! -d ".git" ]; then
  git clone https://github.com/eprovst/supanrf.git
  cd ./supanrf
fi
make -B
