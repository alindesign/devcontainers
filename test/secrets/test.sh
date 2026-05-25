#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "sops present" command -v sops
check "sops --version works" sh -c 'sops --version | head -n1 | grep -iE "sops"'
check "age present" command -v age
check "age-keygen present" command -v age-keygen
check "pass present (default on)" command -v pass
check "gpg present (default on)" command -v gpg

reportResults
