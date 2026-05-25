#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "rustc present" command -v rustc
check "cargo present" command -v cargo
check "rustup present" command -v rustup
check "rustfmt present" command -v rustfmt
check "rustc version works" sh -c 'rustc --version | grep -E "^rustc [0-9]+\\."'
check "CARGO_HOME shared" test -d /usr/local/cargo/bin
check "RUSTUP_HOME shared" test -d /usr/local/rustup

reportResults
