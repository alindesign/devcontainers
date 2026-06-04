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
# Uses Debian's pg_createcluster / pg_ctlcluster wrappers — they handle the
# socket dir, /etc paths, hba defaults, and start-conf semantics correctly.
set -e

# shellcheck disable=SC1091
. /etc/devcontainer-services.d/20-postgres.conf

CLUSTER_DIR="/var/lib/postgresql/${PG_VERSION}/main"
CONF_DIR="/etc/postgresql/${PG_VERSION}/main"

# Re-chown every boot — guards against uid drift across apt upgrades AND
# fresh named-volume mounts (which start owned by root).
install -d -m 0755 -o postgres -g postgres /var/lib/postgresql
chown -R postgres:postgres /var/lib/postgresql

install -d -m 02775 -o postgres -g postgres /var/run/postgresql /var/log/postgresql

# (Re)create the cluster if missing (covers fresh named-volume mount).
if [ ! -s "${CLUSTER_DIR}/PG_VERSION" ]; then
  # Clean any stale /etc config left over from a removed cluster on the
  # underlying fs (gets shadowed when /var/lib/postgresql is volume-mounted).
  rm -rf "${CONF_DIR}"
  pg_createcluster "${PG_VERSION}" main \
    --start-conf=manual \
    --datadir="${CLUSTER_DIR}" \
    -- \
    --auth-local=trust \
    --auth-host=scram-sha-256 \
    --encoding=UTF8 \
    --locale=C.UTF-8

  # Drop our override snippet via Debian's conf.d include pattern.
  install -d -m 0755 -o postgres -g postgres "${CONF_DIR}/conf.d"
  cat > "${CONF_DIR}/conf.d/devcontainer.conf" <<CONF
listen_addresses = '127.0.0.1'
port = ${PG_PORT}
CONF
  chown postgres:postgres "${CONF_DIR}/conf.d/devcontainer.conf"
fi

# Skip if already online.
if pg_lsclusters --no-header 2>/dev/null | awk -v ver="${PG_VERSION}" '$1==ver && $2=="main" {print $4}' | grep -qx online; then
  :
else
  pg_ctlcluster "${PG_VERSION}" main start
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
  tail -n 80 "/var/log/postgresql/postgresql-${PG_VERSION}-main.log" 2>/dev/null >&2 || true
  exit 1
fi

# One-shot bootstrap.
SENTINEL="${CLUSTER_DIR}/.devcontainer-bootstrapped"
if [ ! -f "${SENTINEL}" ]; then
  if [ -n "${ROOT_PASSWORD}" ]; then
    sudo -u postgres psql -p "${PG_PORT}" -v ON_ERROR_STOP=1 \
      -v rootpw="${ROOT_PASSWORD}" <<'SQL'
ALTER USER postgres WITH PASSWORD :'rootpw';
SQL
  fi
  if [ -n "${CREATE_USER}" ]; then
    sudo -u postgres psql -p "${PG_PORT}" -v ON_ERROR_STOP=1 \
      -v username="${CREATE_USER}" -v password="${CREATE_PASSWORD}" <<'SQL'
SELECT format('CREATE ROLE %I WITH LOGIN CREATEDB PASSWORD %L', :'username', :'password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'username')
\gexec
SQL
  fi
  if [ -n "${CREATE_DATABASE}" ]; then
    if ! sudo -u postgres psql -p "${PG_PORT}" -tAc "SELECT 1 FROM pg_database WHERE datname='${CREATE_DATABASE//\'/}'" | grep -q 1; then
      OWNER="${CREATE_USER:-postgres}"
      sudo -u postgres psql -p "${PG_PORT}" -v ON_ERROR_STOP=1 \
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
