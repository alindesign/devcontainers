#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "nvim absent" sh -c '! command -v nvim'
check "zsh still present" command -v zsh

reportResults
