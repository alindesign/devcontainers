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
check "nvim version >= 0.10 (LazyVim requirement)" sh -c "nvim --version | head -1 | awk '{print \$2}' | sed 's/^v//' | awk -F. '{exit (\$1*100+\$2 >= 10) ? 0 : 1}'"
check "vscode .zshrc written" test -f /home/vscode/.zshrc
check "starship config written" test -f /home/vscode/.config/starship.toml
check "nvim init.lua written" test -f /home/vscode/.config/nvim/init.lua
check "LazyVim lazy.lua bootstrap present" test -f /home/vscode/.config/nvim/lua/config/lazy.lua
check "LazyVim extras manifest present" test -f /home/vscode/.config/nvim/lazyvim.json
check "treesitter build deps (gcc) present" command -v gcc
check "treesitter build deps (make) present" command -v make
check "git delta configured" sh -c 'git config --global --get core.pager | grep -q delta'
check "vscode default shell zsh" sh -c 'getent passwd vscode | cut -d: -f7 | grep -q zsh'
check "gh present" command -v gh
check "gh credential helper for github.com" sh -c 'git config --global --get credential.https://github.com.helper | grep -q "gh auth git-credential"'
check "gh credential helper for gist.github.com" sh -c 'git config --global --get credential.https://gist.github.com.helper | grep -q "gh auth git-credential"'
check "atuin present" command -v atuin
check "atuin config written" test -f /home/vscode/.config/atuin/config.toml
check "atuin init wired into .zshrc" sh -c 'grep -q "atuin init zsh" /home/vscode/.zshrc'
check "tmux present" command -v tmux
check "tmux config written" test -f /home/vscode/.tmux.conf
check "tmux prefix set to C-a" sh -c 'grep -q "set -g prefix C-a" /home/vscode/.tmux.conf'
check "TPM cloned to ~/.tmux/plugins/tpm" test -d /home/vscode/.tmux/plugins/tpm
check "catppuccin plugin pre-installed" test -d /home/vscode/.tmux/plugins/tmux

reportResults
