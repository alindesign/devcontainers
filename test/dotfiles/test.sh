#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "zsh present" command -v zsh
check "starship present" command -v starship
check "ripgrep present" command -v rg
check "fd present" command -v fd
check "bat present" command -v bat
check "fzf present" command -v fzf
check "eza present" command -v eza
check "zoxide present" command -v zoxide
check "git-delta present" command -v delta
check "jq present" command -v jq
check "neovim present" command -v nvim
check "vscode .zshrc written" test -f /home/vscode/.zshrc
check "starship config written" test -f /home/vscode/.config/starship.toml
check "nvim init written" test -f /home/vscode/.config/nvim/init.lua
check "git delta configured" sh -c 'git config --global --get core.pager | grep -q delta'
check "vscode default shell zsh" sh -c 'getent passwd vscode | cut -d: -f7 | grep -q zsh'

reportResults
