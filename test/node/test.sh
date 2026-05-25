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
check "nvm dir exists" test -s /usr/local/share/nvm/nvm.sh
# Concrete write probe — `test -w` can be ambiguous depending on ACLs;
# this proves the user can actually create and remove files in NVM_DIR.
check "nvm dir writable by current user" sh -c '
  probe=/usr/local/share/nvm/.write-probe-$$
  ls -ld /usr/local/share/nvm
  id
  touch "$probe" && rm "$probe"
'
check "node usable by current user" sh -c 'node --version | grep -E "^v[0-9]+"'

reportResults
