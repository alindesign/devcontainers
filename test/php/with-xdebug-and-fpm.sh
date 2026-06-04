#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "php present" command -v php
check "xdebug loaded" sh -c 'php -m | grep -qi "^xdebug$"'
check "php-fpm binary present" sh -c 'ls /usr/sbin/php-fpm* 2>/dev/null | head -n1'
check "fpm pool runs as vscode" sh -c 'grep -qE "^user = vscode" /etc/php/8.4/fpm/pool.d/www.conf'

reportResults
