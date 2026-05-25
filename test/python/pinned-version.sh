#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "python major.minor is 3.12" sh -c 'python --version | grep -E "^Python 3\\.12\\."'

reportResults
