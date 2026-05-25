#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Compose check: dotfiles + node must coexist and zsh must see node via NVM_DIR hook.
check "zsh present" command -v zsh
check "starship present" command -v starship
check "node present" command -v node
check "pnpm present" command -v pnpm
check "zshrc sources NVM_DIR" sh -c 'grep -q "NVM_DIR" "$HOME/.zshrc"'
check "node usable in interactive zsh" sh -c 'zsh -ic "node --version" | grep -E "^v[0-9]+"'

reportResults
