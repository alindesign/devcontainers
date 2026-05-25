#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "python present" command -v python
check "poetry present" command -v poetry
check "poetry --version works" sh -c 'poetry --version | grep -iE "poetry .*[0-9]+\\."'
check "uv not present" sh -c '! command -v uv'

reportResults
