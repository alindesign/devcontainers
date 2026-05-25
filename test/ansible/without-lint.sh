#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "ansible present" command -v ansible
check "ansible-lint absent" sh -c '! command -v ansible-lint'

reportResults
