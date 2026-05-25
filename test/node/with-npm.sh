#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "node present" command -v node
check "npm present" command -v npm
check "pnpm not on PATH" sh -c '! command -v pnpm'
check "yarn not on PATH" sh -c '! command -v yarn'
check "npm works" sh -c 'npm --version | grep -E "^[0-9]+\\."'

reportResults
