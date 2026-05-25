#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "tofu present" command -v tofu
check "tofu version works" sh -c 'tofu version | head -n1 | grep -iE "tofu"'
check "terraform alias present" sh -c 'readlink /usr/local/bin/terraform | grep -q tofu'
check "tflint present (default on)" command -v tflint

reportResults
