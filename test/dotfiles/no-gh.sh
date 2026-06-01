#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "gh absent" sh -c '! command -v gh'
check "no github credential helper" sh -c '! git config --global --get credential.https://github.com.helper'

reportResults
