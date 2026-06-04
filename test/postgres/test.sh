#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

unset PGHOST PGPORT PGUSER PGPASSWORD

# Active probe — dispatcher does not run from `features test`.
sudo /etc/devcontainer-services.d/20-postgres.sh

PG_VERSION="$(find /usr/lib/postgresql -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -n | tail -n1)"

check "postgres binary present" test -x "/usr/lib/postgresql/${PG_VERSION}/bin/postgres"
check "psql client present" command -v psql
check "dispatcher script installed" test -x /etc/devcontainer-services.d/20-postgres.sh
check "entrypoint wrapper installed" test -x /usr/local/share/postgres-init.sh
check "postgres accepting connections" sh -c "sudo /usr/lib/postgresql/${PG_VERSION}/bin/pg_isready -h /var/run/postgresql -p 5432 | grep -q 'accepting connections'"

reportResults
