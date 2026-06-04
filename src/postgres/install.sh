#!/usr/bin/env bash
# Feature: postgres
# Installs PostgreSQL from PGDG (apt.postgresql.org), configures it to bind
# 127.0.0.1, and registers a services-dispatcher script that initialises the
# cluster and starts the server on container boot.
set -euo pipefail

PG_VERSION="${VERSION:-18}"
ROOT_PASSWORD="${ROOTPASSWORD:-postgres}"
CREATE_DATABASE="${CREATEDATABASE:-}"
CREATE_USER="${CREATEUSER:-}"
CREATE_PASSWORD="${CREATEPASSWORD:-}"
PG_PORT="${PORT:-5432}"

if [ "$(id -u)" -ne 0 ]; then
  echo "postgres feature: must run as root" >&2
  exit 1
fi

if ! echo "${PG_VERSION}" | grep -Eq '^[0-9]+$'; then
  echo "postgres feature: invalid version '${PG_VERSION}' (expected major number, e.g. '18')" >&2
  exit 1
fi

echo "postgres feature: version=${PG_VERSION} port=${PG_PORT}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release sudo

# --- PGDG apt repo (pin directly to the .asc, not pgdg-keyring) -------------
# shellcheck source=/dev/null
. /etc/os-release
ARCH="$(dpkg --print-architecture)"

# PGDG publishes for all current Debian + Ubuntu codenames; fall back to a
# recent LTS for interim releases.
PG_SUPPORTED_UBUNTU="resolute plucky noble jammy focal"
PG_SUPPORTED_DEBIAN="trixie bookworm bullseye"
codename="${VERSION_CODENAME:-noble}"

case "${ID}" in
  debian)
    if ! echo "${PG_SUPPORTED_DEBIAN}" | grep -qw "${codename}"; then
      echo "postgres feature: '${codename}' has no PGDG channel; falling back to bookworm"
      codename="bookworm"
    fi
    ;;
  ubuntu|*)
    if ! echo "${PG_SUPPORTED_UBUNTU}" | grep -qw "${codename}"; then
      echo "postgres feature: '${codename}' has no PGDG channel; falling back to noble"
      codename="noble"
    fi
    ;;
esac

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | gpg --batch --yes --dearmor -o /etc/apt/keyrings/pgdg.gpg
chmod 0644 /etc/apt/keyrings/pgdg.gpg

echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt ${codename}-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list

apt-get update -y
apt-get install -y --no-install-recommends \
  "postgresql-${PG_VERSION}" \
  "postgresql-client-${PG_VERSION}" \
  "postgresql-contrib-${PG_VERSION}"

apt-get clean
rm -rf /var/lib/apt/lists/*

# Stop the cluster auto-started by the apt postinst — dispatcher will handle.
pg_ctlcluster "${PG_VERSION}" main stop 2>/dev/null || true
pg_dropcluster "${PG_VERSION}" main --stop 2>/dev/null || true

# Make sure /var/lib/postgresql is owned by postgres (it's a named volume mount
# that may be empty on first boot, or pre-populated by a previous container).
install -d -m 0700 -o postgres -g postgres /var/lib/postgresql

# --- services dispatcher script ---------------------------------------------
install -d -m 0755 /etc/devcontainer-services.d

cat > /etc/devcontainer-services.d/20-postgres.conf <<EOF
PG_VERSION=$(printf '%q' "${PG_VERSION}")
PG_PORT=$(printf '%q' "${PG_PORT}")
ROOT_PASSWORD=$(printf '%q' "${ROOT_PASSWORD}")
CREATE_DATABASE=$(printf '%q' "${CREATE_DATABASE}")
CREATE_USER=$(printf '%q' "${CREATE_USER}")
CREATE_PASSWORD=$(printf '%q' "${CREATE_PASSWORD}")
EOF
chmod 0600 /etc/devcontainer-services.d/20-postgres.conf

cat > /etc/devcontainer-services.d/20-postgres.sh <<'EOF'
#!/usr/bin/env bash
# devcontainer service: postgres
# Direct initdb + pg_ctl. Mirrors the official postgres docker image pattern
# (more reliable than Debian's pg_createcluster which validates state in ways
# that don't compose well with volume-mounted data dirs).
set -e

# PGHOST in the parent env would push psql to TCP. Force socket-only
# admin connections so peer/trust auth on the local socket works.
unset PGHOST PGPORT PGUSER PGPASSWORD

# shellcheck disable=SC1091
. /etc/devcontainer-services.d/20-postgres.conf

PGDATA="/var/lib/postgresql/${PG_VERSION}/main"
BIN_DIR="/usr/lib/postgresql/${PG_VERSION}/bin"

# Runtime dirs that postgres needs MUST exist before initdb runs — initdb's
# final pg_ctl start uses the default unix socket dir.
install -d -m 02775 -o postgres -g postgres /var/run/postgresql /var/log/postgresql
install -d -m 0755 -o postgres -g postgres /var/lib/postgresql "/var/lib/postgresql/${PG_VERSION}"
chown -R postgres:postgres /var/lib/postgresql

# Initialise on fresh data dir.
if [ ! -s "${PGDATA}/PG_VERSION" ]; then
  install -d -m 0700 -o postgres -g postgres "${PGDATA}"
  # Strip any stale unix socket files from /tmp that could confuse the
  # post-bootstrap pg_ctl that initdb invokes.
  find /tmp -maxdepth 1 -name '.s.PGSQL.*' -delete 2>/dev/null || true

  sudo -u postgres "${BIN_DIR}/initdb" \
    -D "${PGDATA}" \
    --auth-local=trust \
    --auth-host=scram-sha-256 \
    --encoding=UTF8 \
    --locale=C.UTF-8

  cat >> "${PGDATA}/postgresql.conf" <<CONF

# devcontainer overrides
listen_addresses = '127.0.0.1'
port = ${PG_PORT}
unix_socket_directories = '/var/run/postgresql'
CONF
  chown postgres:postgres "${PGDATA}/postgresql.conf"
fi

# Skip if already running.
if sudo -u postgres "${BIN_DIR}/pg_ctl" -D "${PGDATA}" status >/dev/null 2>&1; then
  :
else
  # Defensive: clear any stale postmaster.pid left behind by initdb's brief
  # post-bootstrap server start (or by a crashed previous container).
  if [ -f "${PGDATA}/postmaster.pid" ]; then
    PID="$(head -n1 "${PGDATA}/postmaster.pid" 2>/dev/null || echo "")"
    if [ -n "${PID}" ] && kill -0 "${PID}" 2>/dev/null; then
      echo "postgres service: postmaster.pid points at live PID ${PID}; refusing to clobber" >&2
      exit 1
    fi
    rm -f "${PGDATA}/postmaster.pid"
  fi

  sudo -u postgres "${BIN_DIR}/pg_ctl" \
    -D "${PGDATA}" \
    -l /var/log/postgresql/postgres.log \
    -w start || {
      echo "postgres service: pg_ctl start failed — dumping log:" >&2
      tail -n 100 /var/log/postgresql/postgres.log >&2 2>/dev/null || true
      exit 1
    }
fi

# Wait for the daemon to accept queries.
ready=0
for _ in $(seq 1 90); do
  if sudo -u postgres pg_isready -h /var/run/postgresql -p "${PG_PORT}" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [ "${ready}" -ne 1 ]; then
  echo "postgres service: server failed to become ready — dumping log:" >&2
  tail -n 100 /var/log/postgresql/postgres.log 2>/dev/null >&2 || true
  exit 1
fi

# One-shot bootstrap.
SENTINEL="${CLUSTER_DIR}/.devcontainer-bootstrapped"
if [ ! -f "${SENTINEL}" ]; then
  if [ -n "${ROOT_PASSWORD}" ]; then
    sudo -u postgres psql -h /var/run/postgresql -p "${PG_PORT}" -v ON_ERROR_STOP=1 \
      -v rootpw="${ROOT_PASSWORD}" <<'SQL'
ALTER USER postgres WITH PASSWORD :'rootpw';
SQL
  fi
  if [ -n "${CREATE_USER}" ]; then
    sudo -u postgres psql -h /var/run/postgresql -p "${PG_PORT}" -v ON_ERROR_STOP=1 \
      -v username="${CREATE_USER}" -v password="${CREATE_PASSWORD}" <<'SQL'
SELECT format('CREATE ROLE %I WITH LOGIN CREATEDB PASSWORD %L', :'username', :'password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'username')
\gexec
SQL
  fi
  if [ -n "${CREATE_DATABASE}" ]; then
    if ! sudo -u postgres psql -h /var/run/postgresql -p "${PG_PORT}" -tAc "SELECT 1 FROM pg_database WHERE datname='${CREATE_DATABASE//\'/}'" | grep -q 1; then
      OWNER="${CREATE_USER:-postgres}"
      sudo -u postgres psql -h /var/run/postgresql -p "${PG_PORT}" -v ON_ERROR_STOP=1 \
        -v dbname="${CREATE_DATABASE}" -v owner="${OWNER}" <<'SQL'
SELECT format('CREATE DATABASE %I OWNER %I', :'dbname', :'owner')
\gexec
SQL
    fi
  fi
  touch "${SENTINEL}"
  chown postgres:postgres "${SENTINEL}"
fi
EOF
chmod 0755 /etc/devcontainer-services.d/20-postgres.sh

install -d -m 0755 -o postgres -g postgres /var/log/postgresql

# --- entrypoint wrapper (shared services dispatcher) ------------------------
cat > /usr/local/share/postgres-init.sh <<'EOF'
#!/usr/bin/env bash
# devcontainer entrypoint: shared services dispatcher.
set -e

SENTINEL=/run/devcontainer-services.dispatched
if [ ! -e "${SENTINEL}" ]; then
  if [ -d /etc/devcontainer-services.d ]; then
    run-parts --regex '^[0-9]+-.*\.sh$' /etc/devcontainer-services.d/ || true
  fi
  touch "${SENTINEL}" 2>/dev/null || true
fi

if [ $# -gt 0 ]; then
  exec "$@"
else
  exec sleep infinity
fi
EOF
chmod 0755 /usr/local/share/postgres-init.sh

# --- profile.d export -------------------------------------------------------
cat > /etc/profile.d/devcontainer-postgres.sh <<EOF
: "\${PGHOST:=127.0.0.1}"
: "\${PGPORT:=${PG_PORT}}"
export PGHOST PGPORT
EOF
chmod 0644 /etc/profile.d/devcontainer-postgres.sh

# --- sanity -----------------------------------------------------------------
"/usr/lib/postgresql/${PG_VERSION}/bin/postgres" --version 2>&1 | head -n1 || true

echo "postgres feature: done"
