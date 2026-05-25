#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "docker present" command -v docker
check "buildx subcommand present" sh -c 'docker buildx version 2>&1 | grep -iE "buildx|github"'
check "compose subcommand present" sh -c 'docker compose version 2>&1 | grep -iE "compose|version"'
check "docker-compose shim present" command -v docker-compose
check "dockerd binary present" command -v dockerd
check "docker-init.sh installed" test -x /usr/local/share/docker-init.sh
check "vscode in docker group" sh -c 'id -nG vscode | grep -qw docker'

reportResults
