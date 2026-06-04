#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "php present" command -v php
check "php is 8.4" sh -c 'php -v | head -n1 | grep -qE " 8\.4\."'
check "composer present" command -v composer
check "composer is v2" sh -c 'composer --version | grep -q "Composer version 2"'
check "mbstring loaded" sh -c 'php -m | grep -qi "^mbstring$"'
check "intl loaded" sh -c 'php -m | grep -qi "^intl$"'
check "pdo_mysql loaded" sh -c 'php -m | grep -qi "^pdo_mysql$"'
check "pdo_pgsql loaded" sh -c 'php -m | grep -qi "^pdo_pgsql$"'
check "redis loaded" sh -c 'php -m | grep -qi "^redis$"'
check "opcache loaded" sh -c 'php -m | grep -qi "^Zend OPcache$"'

reportResults
