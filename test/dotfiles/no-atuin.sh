#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "atuin absent" sh -c '! command -v atuin'
check "no atuin config" sh -c '! test -f /home/vscode/.config/atuin/config.toml'
check "zsh still present" command -v zsh

reportResults
