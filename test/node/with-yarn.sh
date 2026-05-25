#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "node present" command -v node
check "npm present" command -v npm
check "yarn present" command -v yarn
check "yarn works" sh -c 'yarn --version | grep -E "^[0-9]+\\."'

reportResults
