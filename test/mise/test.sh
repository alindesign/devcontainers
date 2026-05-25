#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "mise binary present" command -v mise
check "mise --version works" sh -c 'mise --version | grep -E "[0-9]+\\."'
check "MISE_DATA_DIR exposed via profile" test -f /etc/profile.d/mise.sh
check "MISE_DATA_DIR exists" test -d /usr/local/share/mise
check "MISE_DATA_DIR writable" sh -c '
  ls -ld /usr/local/share/mise
  id
  probe=/usr/local/share/mise/.write-probe-$$
  touch "$probe" && rm "$probe"
'
check "bashrc activates mise" sh -c 'grep -q "mise activate bash" "$HOME/.bashrc"'

reportResults
