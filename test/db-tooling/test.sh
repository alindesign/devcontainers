#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "psql present" command -v psql
check "mysql present" command -v mysql
check "redis-cli present" command -v redis-cli
check "mongosh present" command -v mongosh

reportResults
