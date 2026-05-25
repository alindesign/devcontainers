#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "go binary present" command -v go
check "go version works" sh -c 'go version | grep -E "^go version go[0-9]+\\."'
check "mise binary present" command -v mise

reportResults
