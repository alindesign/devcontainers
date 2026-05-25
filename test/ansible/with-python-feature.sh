#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Both python and ansible installed: ensure they coexist and uv from python
# feature is what ansible uses (no double-bootstrap).
check "uv present" command -v uv
check "ansible present" command -v ansible
check "ansible-lint present" command -v ansible-lint
check "python --version" sh -c 'python --version | grep -E "^Python 3\\."'

reportResults
