#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "bun present" command -v bun
check "bunx present" command -v bunx
check "bun --version works" sh -c 'bun --version | grep -E "^[0-9]+\\."'
check "BUN_INSTALL profile present" test -f /etc/profile.d/bun.sh
check "BUN_INSTALL dir exists" test -d /usr/local/bun
check "BUN_INSTALL writable by current user" sh -c '
  ls -ld /usr/local/bun
  id
  probe=/usr/local/bun/.write-probe-$$
  touch "$probe" && rm "$probe"
'

reportResults
