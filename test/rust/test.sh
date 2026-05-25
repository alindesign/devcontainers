#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "rustc present" command -v rustc
check "cargo present" command -v cargo
check "rustfmt present" command -v rustfmt
check "rustc version works" sh -c 'rustc --version | grep -E "^rustc [0-9]+\\."'
check "mise binary present" command -v mise

reportResults
