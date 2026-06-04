#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "php present" command -v php
check "symfony CLI present" command -v symfony
check "symfony CLI runs" sh -c 'symfony version 2>&1 | grep -qi symfony'

reportResults
