#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

sudo /etc/devcontainer-services.d/30-redis.sh

check "redis rejects unauth ping" sh -c 'redis-cli -h 127.0.0.1 -p 6379 ping 2>&1 | grep -qi "NOAUTH"'
check "redis answers with password" sh -c 'redis-cli -h 127.0.0.1 -p 6379 -a s3cr3t --no-auth-warning ping | grep -q PONG'

reportResults
