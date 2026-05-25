#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "node present" command -v node
check "npm present" command -v npm
check "claude present" command -v claude
check "claude binary executable" sh -c 'claude --version 2>&1 | head -n1 || true'

reportResults
