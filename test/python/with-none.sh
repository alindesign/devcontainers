#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "python present" command -v python
check "pip present" command -v pip
check "uv not present" sh -c '! command -v uv'
check "poetry not present" sh -c '! command -v poetry'

reportResults
