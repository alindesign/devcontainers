#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Active probe — dispatcher does not run from `features test`.
sudo /etc/devcontainer-services.d/20-postgres.sh

PG_VERSION="$(find /usr/lib/postgresql -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -n | tail -n1)"

check "postgres binary present" test -x "/usr/lib/postgresql/${PG_VERSION}/bin/postgres"
check "psql client present" command -v psql
check "dispatcher script installed" test -x /etc/devcontainer-services.d/20-postgres.sh
check "entrypoint wrapper installed" test -x /usr/local/share/postgres-init.sh
check "cluster initialized" test -s "/var/lib/postgresql/${PG_VERSION}/main/PG_VERSION"
check "postgres accepting connections" sh -c "sudo -u postgres /usr/lib/postgresql/${PG_VERSION}/bin/pg_isready -h 127.0.0.1 -p 5432 | grep -q 'accepting connections'"
check "appdb exists" sh -c "sudo -u postgres psql -tAc \"SELECT 1 FROM pg_database WHERE datname='appdb'\" | grep -q 1"
check "appuser can connect via TCP" sh -c 'PGPASSWORD=apppass psql -h 127.0.0.1 -U appuser -d appdb -tAc "SELECT 1" | grep -q 1'

reportResults
