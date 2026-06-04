#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source dev-container-features-test-lib

sudo /etc/devcontainer-services.d/20-postgres.sh

unset PGHOST PGPORT PGUSER PGPASSWORD

PG_VERSION="$(find /usr/lib/postgresql -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -n | tail -n1)"

check "postgres accepting connections" sh -c "sudo -u postgres /usr/lib/postgresql/${PG_VERSION}/bin/pg_isready -h /var/run/postgresql -p 5432 | grep -q 'accepting connections'"
check "appdb exists" sh -c "sudo -u postgres psql -h /var/run/postgresql -tAc \"SELECT 1 FROM pg_database WHERE datname='appdb'\" | grep -q 1"
check "appuser exists" sh -c "sudo -u postgres psql -h /var/run/postgresql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='appuser'\" | grep -q 1"
check "appuser can connect via TCP" sh -c 'PGPASSWORD=apppass psql -h 127.0.0.1 -U appuser -d appdb -tAc "SELECT 1" | grep -q 1'

reportResults
