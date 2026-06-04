#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

sudo /etc/devcontainer-services.d/10-mysql.sh

unset MYSQL_HOST MYSQL_TCP_PORT MYSQL_PWD

check "mysqld accepting connections" sh -c 'sudo mysqladmin --socket=/var/run/mysqld/mysqld.sock --connect-timeout=5 ping | grep -q "is alive"'
check "appdb exists" sh -c 'sudo mysql --protocol=socket --socket=/var/run/mysqld/mysqld.sock -uroot -Nse "SHOW DATABASES" | grep -qx appdb'
check "appuser exists" sh -c 'sudo mysql --protocol=socket --socket=/var/run/mysqld/mysqld.sock -uroot -Nse "SELECT user FROM mysql.user WHERE user='\''appuser'\''" | grep -qx appuser'
check "appuser can connect via TCP" sh -c 'mysql --protocol=tcp -h 127.0.0.1 -uappuser -papppass -e "SELECT 1;" appdb | grep -q 1'

reportResults
