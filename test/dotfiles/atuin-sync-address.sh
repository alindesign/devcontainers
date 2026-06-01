#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "atuin config written" test -f /home/vscode/.config/atuin/config.toml
check "sync_address set from option" sh -c 'grep -E "^sync_address = \"https://atuin.example.com\"" /home/vscode/.config/atuin/config.toml'
check "default sync_address comment replaced" sh -c '! grep -E "^# sync_address" /home/vscode/.config/atuin/config.toml'

reportResults
