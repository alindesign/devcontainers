#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "psql present" command -v psql
check "mysql present" command -v mysql
check "redis-cli absent" sh -c '! command -v redis-cli'
check "mongosh absent" sh -c '! command -v mongosh'

reportResults
