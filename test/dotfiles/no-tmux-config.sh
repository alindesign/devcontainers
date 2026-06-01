#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "tmux still installed" command -v tmux
check "tmux config not written" sh -c '! test -f /home/vscode/.tmux.conf'

reportResults
