#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

sudo /etc/devcontainer-services.d/40-mailpit.sh

check "mailpit binary present" command -v mailpit
check "dispatcher script installed" test -x /etc/devcontainer-services.d/40-mailpit.sh
check "entrypoint wrapper installed" test -x /usr/local/share/mailpit-init.sh
check "mailpit UI responds" sh -c 'curl -fsS http://127.0.0.1:8025/api/v1/info | grep -qi version'

reportResults
