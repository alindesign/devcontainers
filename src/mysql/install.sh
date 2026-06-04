#!/usr/bin/env bash
# Feature: mysql
# Installs MySQL Community Server via Oracle's APT repo, configures it to bind
# 127.0.0.1, and registers a services-dispatcher script that initialises and
# starts mysqld on container boot.
set -euo pipefail

MYSQL_VERSION="${VERSION:-8.4}"
ROOT_PASSWORD="${ROOTPASSWORD:-}"
CREATE_DATABASE="${CREATEDATABASE:-}"
CREATE_USER="${CREATEUSER:-}"
CREATE_PASSWORD="${CREATEPASSWORD:-}"
MYSQL_PORT="${PORT:-3306}"

if [ "$(id -u)" -ne 0 ]; then
  echo "mysql feature: must run as root" >&2
  exit 1
fi

case "${MYSQL_VERSION}" in
  8.0)             MYSQL_CHANNEL="mysql-8.0" ;;
  8.4)             MYSQL_CHANNEL="mysql-8.4-lts" ;;
  9.*|innovation)  MYSQL_CHANNEL="mysql-innovation" ;;
  *)
    echo "mysql feature: invalid version '${MYSQL_VERSION}' (expected 8.0, 8.4, or 9.x)" >&2
    exit 1
    ;;
esac

echo "mysql feature: version=${MYSQL_VERSION} channel=${MYSQL_CHANNEL} port=${MYSQL_PORT}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release sudo psmisc

# --- MySQL Community APT repo -----------------------------------------------
# shellcheck source=/dev/null
. /etc/os-release
ARCH="$(dpkg --print-architecture)"

# MySQL apt repo currently publishes for these codenames; fall back to noble
# on interim Ubuntu releases.
MYSQL_SUPPORTED_UBUNTU="noble jammy"
MYSQL_SUPPORTED_DEBIAN="bookworm bullseye"
codename="${VERSION_CODENAME:-noble}"
repo_base="ubuntu"

case "${ID}" in
  debian)
    repo_base="debian"
    if ! echo "${MYSQL_SUPPORTED_DEBIAN}" | grep -qw "${codename}"; then
      echo "mysql feature: '${codename}' has no MySQL APT channel; falling back to bookworm"
      codename="bookworm"
    fi
    ;;
  ubuntu|*)
    if ! echo "${MYSQL_SUPPORTED_UBUNTU}" | grep -qw "${codename}"; then
      echo "mysql feature: '${codename}' has no MySQL APT channel; falling back to noble"
      codename="noble"
    fi
    ;;
esac

install -d -m 0755 /etc/apt/keyrings
# MySQL rotates their signing key periodically (RPM-GPG-KEY-mysql-2023 expired
# 2025-10; 2025 key is current). Fetch the newest available.
MYSQL_KEY_URL=""
for year in 2025 2024 2023; do
  if curl -fsSI "https://repo.mysql.com/RPM-GPG-KEY-mysql-${year}" >/dev/null 2>&1; then
    MYSQL_KEY_URL="https://repo.mysql.com/RPM-GPG-KEY-mysql-${year}"
    break
  fi
done
if [ -z "${MYSQL_KEY_URL}" ]; then
  echo "mysql feature: ERROR — could not fetch any MySQL GPG key from repo.mysql.com" >&2
  exit 1
fi
echo "mysql feature: using MySQL signing key ${MYSQL_KEY_URL##*/}"
curl -fsSL "${MYSQL_KEY_URL}" \
  | gpg --batch --yes --dearmor -o /etc/apt/keyrings/mysql.gpg
chmod 0644 /etc/apt/keyrings/mysql.gpg

echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/mysql.gpg] http://repo.mysql.com/apt/${repo_base}/ ${codename} ${MYSQL_CHANNEL}" \
  > /etc/apt/sources.list.d/mysql.list

# Pre-seed debconf so the postinst is non-interactive and leaves root with an
# empty password (we re-secure during the boot init script).
{
  echo "mysql-community-server mysql-community-server/root-pass password "
  echo "mysql-community-server mysql-community-server/re-root-pass password "
  echo "mysql-community-server mysql-server/default-auth-override select Use Strong Password Encryption (RECOMMENDED)"
} | debconf-set-selections

apt-get update -y
apt-get install -y --no-install-recommends mysql-community-server mysql-community-client

apt-get clean
rm -rf /var/lib/apt/lists/*

# Disable any auto-started service so we control startup from the dispatcher.
systemctl disable mysql 2>/dev/null || true
service mysql stop 2>/dev/null || true
killall -q mysqld 2>/dev/null || true

# --- minimal config (bind 127.0.0.1, configurable port, dev-friendly) -------
install -d -m 0755 /etc/mysql/conf.d
cat > /etc/mysql/conf.d/devcontainer.cnf <<EOF
[mysqld]
bind-address = 127.0.0.1
port = ${MYSQL_PORT}
skip-name-resolve = 1
default-authentication-plugin = caching_sha2_password
innodb_buffer_pool_size = 256M
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
EOF
chmod 0644 /etc/mysql/conf.d/devcontainer.cnf

install -d -m 0755 -o mysql -g mysql /var/lib/mysql /var/run/mysqld /var/log/mysql

# --- services dispatcher script ---------------------------------------------
install -d -m 0755 /etc/devcontainer-services.d

# Option values that may contain quotes/spaces (passwords, names) need safe
# encoding for the runtime sourcing. printf '%q' produces bash-loadable
# tokens; the dispatcher reads them from the .conf at boot. The .conf is
# excluded from run-parts by the regex (^[0-9]+-.*\.sh$).
cat > /etc/devcontainer-services.d/10-mysql.conf <<EOF
MYSQL_VERSION=$(printf '%q' "${MYSQL_VERSION}")
MYSQL_PORT=$(printf '%q' "${MYSQL_PORT}")
ROOT_PASSWORD=$(printf '%q' "${ROOT_PASSWORD}")
CREATE_DATABASE=$(printf '%q' "${CREATE_DATABASE}")
CREATE_USER=$(printf '%q' "${CREATE_USER}")
CREATE_PASSWORD=$(printf '%q' "${CREATE_PASSWORD}")
EOF
chmod 0600 /etc/devcontainer-services.d/10-mysql.conf

cat > /etc/devcontainer-services.d/10-mysql.sh <<'EOF'
#!/usr/bin/env bash
# devcontainer service: mysql
set -e

# shellcheck disable=SC1091
. /etc/devcontainer-services.d/10-mysql.conf

DATADIR=/var/lib/mysql
SOCKET=/var/run/mysqld/mysqld.sock

install -d -m 0755 -o mysql -g mysql /var/run/mysqld /var/log/mysql
chown -R mysql:mysql "${DATADIR}"

# Initialise data dir if empty (covers first boot AND fresh named volume).
if [ ! -d "${DATADIR}/mysql" ]; then
  mysqld --initialize-insecure --user=mysql --datadir="${DATADIR}"
fi

# Skip if a daemon is already up.
if mysqladmin --socket="${SOCKET}" --silent --connect-timeout=2 ping >/dev/null 2>&1; then
  exit 0
fi

nohup mysqld --user=mysql --datadir="${DATADIR}" --port="${MYSQL_PORT}" \
  > /var/log/mysql/init.log 2>&1 &

# Wait up to ~90s for the daemon to accept connections (cold start on a
# fresh data dir + slow CI runner can take 30-60s).
ready=0
for _ in $(seq 1 180); do
  if mysqladmin --socket="${SOCKET}" --silent --connect-timeout=1 ping >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.5
done
if [ "${ready}" -ne 1 ]; then
  echo "mysql service: daemon failed to become ready within 90s — dumping /var/log/mysql/init.log:" >&2
  tail -n 80 /var/log/mysql/init.log >&2 || true
  exit 1
fi

# One-shot bootstrap (root password, database, user) — sentinel'd to data dir.
SENTINEL="${DATADIR}/.devcontainer-bootstrapped"
if [ ! -f "${SENTINEL}" ]; then
  if [ -n "${ROOT_PASSWORD}" ]; then
    mysql --socket="${SOCKET}" -uroot -e \
      "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD//\'/\'\'}'; FLUSH PRIVILEGES;"
  fi
  if [ -n "${CREATE_DATABASE}" ]; then
    mysql --socket="${SOCKET}" -uroot -e \
      "CREATE DATABASE IF NOT EXISTS \`${CREATE_DATABASE//\`/}\`;"
  fi
  if [ -n "${CREATE_USER}" ]; then
    SCOPE="${CREATE_DATABASE:-*}"
    mysql --socket="${SOCKET}" -uroot -e \
      "CREATE USER IF NOT EXISTS '${CREATE_USER//\'/\'\'}'@'%' IDENTIFIED BY '${CREATE_PASSWORD//\'/\'\'}'; \
       GRANT ALL PRIVILEGES ON \`${SCOPE//\`/}\`.* TO '${CREATE_USER//\'/\'\'}'@'%'; \
       FLUSH PRIVILEGES;"
  fi
  touch "${SENTINEL}"
fi
EOF
chmod 0755 /etc/devcontainer-services.d/10-mysql.sh

# --- entrypoint wrapper (shared services dispatcher) ------------------------
cat > /usr/local/share/mysql-init.sh <<'EOF'
#!/usr/bin/env bash
# devcontainer entrypoint: shared services dispatcher.
# Re-runnable; sentinel prevents re-dispatch when multiple feature entrypoints chain.
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
chmod 0755 /usr/local/share/mysql-init.sh

# --- profile.d export so MYSQL_HOST/MYSQL_PORT are set in every shell -------
cat > /etc/profile.d/devcontainer-mysql.sh <<EOF
: "\${MYSQL_HOST:=127.0.0.1}"
: "\${MYSQL_PORT:=${MYSQL_PORT}}"
export MYSQL_HOST MYSQL_PORT
EOF
chmod 0644 /etc/profile.d/devcontainer-mysql.sh

# --- sanity -----------------------------------------------------------------
mysqld --version 2>&1 | head -n1 || true

echo "mysql feature: done"
