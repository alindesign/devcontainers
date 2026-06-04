#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "frankenphp binary present" command -v frankenphp
check "frankenphp executable" test -x /usr/local/bin/frankenphp
check "frankenphp version runs" sh -c 'frankenphp version 2>&1 | grep -qi frankenphp'
check "cap_net_bind_service set" sh -c 'getcap /usr/local/bin/frankenphp | grep -q cap_net_bind_service'

reportResults
