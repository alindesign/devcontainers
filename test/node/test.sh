#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "node present" command -v node
check "npm present" command -v npm
check "pnpm present" command -v pnpm
check "corepack present" command -v corepack
check "node major >= 18" sh -c 'node -e "process.exit(parseInt(process.versions.node) < 18 ? 1 : 0)"'
check "pnpm works" sh -c 'pnpm --version | grep -E "^[0-9]+\\."'
check "mise binary present" command -v mise
check "MISE_DATA_DIR exists" test -d /usr/local/share/mise
check "MISE_DATA_DIR writable by current user" sh -c '
  ls -ld /usr/local/share/mise
  id
  probe=/usr/local/share/mise/.write-probe-$$
  touch "$probe" && rm "$probe"
'
check "node usable by current user" sh -c 'node --version | grep -E "^v[0-9]+"'

reportResults
