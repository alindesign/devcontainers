#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "aws binary present" command -v aws
check "aws --version is v2" sh -c 'aws --version 2>&1 | grep -q "^aws-cli/2\\."'
check "install dir present" test -d /usr/local/aws-cli

reportResults
