#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

sudo /etc/devcontainer-services.d/30-redis.sh

check "redis-server binary present" command -v redis-server
check "redis-cli binary present" command -v redis-cli
check "dispatcher script installed" test -x /etc/devcontainer-services.d/30-redis.sh
check "entrypoint wrapper installed" test -x /usr/local/share/redis-init.sh
check "redis responds to PING" sh -c 'redis-cli -h 127.0.0.1 -p 6379 ping | grep -q PONG'

reportResults
