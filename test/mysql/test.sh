#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

# `devcontainer features test` does not exec the entrypoint chain. Active probe:
# start the service via the dispatcher script ourselves, then verify the daemon.
sudo /etc/devcontainer-services.d/10-mysql.sh

check "mysqld binary present" command -v mysqld
check "mysql client present" command -v mysql
check "dispatcher script installed" test -x /etc/devcontainer-services.d/10-mysql.sh
check "entrypoint wrapper installed" test -x /usr/local/share/mysql-init.sh
check "data dir initialized" test -d /var/lib/mysql/mysql
check "mysqld accepting connections" sh -c 'sudo mysqladmin --socket=/var/run/mysqld/mysqld.sock --connect-timeout=5 ping | grep -q "is alive"'
check "appdb exists" sh -c 'sudo mysql --socket=/var/run/mysqld/mysqld.sock -uroot -Nse "SHOW DATABASES" | grep -qx appdb'
check "appuser can connect via TCP" sh -c 'mysql -h 127.0.0.1 -uappuser -papppass -e "SELECT 1;" appdb | grep -q 1'

reportResults
