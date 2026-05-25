#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "node major is 20" sh -c 'node --version | grep -q "^v20\\."'

reportResults
