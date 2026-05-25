#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "git user.name set" sh -c 'git config --global user.name | grep -q "Test User"'
check "git user.email set" sh -c 'git config --global user.email | grep -q "test@example.com"'

reportResults
