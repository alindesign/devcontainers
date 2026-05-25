#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "python present" command -v python
check "python3 present" command -v python3
check "pip present" command -v pip
check "python --version works" sh -c 'python --version | grep -E "^Python [0-9]+\\."'
check "uv present (default pm)" command -v uv
check "uv --version works" sh -c 'uv --version | grep -E "^uv [0-9]+\\."'
check "mise binary present" command -v mise
check "/etc/mise/config.toml has python" sh -c 'grep -q "^python = " /etc/mise/config.toml'

reportResults
