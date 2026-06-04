#!/usr/bin/env bash
# Feature: redis
# Installs Redis (default) or Valkey (drop-in BSD-3 fork) and registers a
# services-dispatcher script that starts the daemon on container boot.
set -euo pipefail

VARIANT="${VARIANT:-redis}"
PASSWORD="${PASSWORD:-}"
REDIS_PORT="${PORT:-6379}"

if [ "$(id -u)" -ne 0 ]; then
  echo "redis feature: must run as root" >&2
  exit 1
fi

case "${VARIANT}" in
  redis|valkey) ;;
  *)
    echo "redis feature: invalid variant '${VARIANT}' (expected 'redis' or 'valkey')" >&2
    exit 1
    ;;
esac

echo "redis feature: variant=${VARIANT} port=${REDIS_PORT}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release sudo

# shellcheck source=/dev/null
. /etc/os-release
ARCH="$(dpkg --print-architecture)"

install -d -m 0755 /etc/apt/keyrings

if [ "${VARIANT}" = "redis" ]; then
  # Official Redis APT repo (packages.redis.io). Supports the major Ubuntu/Debian codenames.
  REDIS_SUPPORTED_UBUNTU="noble jammy focal"
  REDIS_SUPPORTED_DEBIAN="trixie bookworm bullseye"
  codename="${VERSION_CODENAME:-noble}"
  case "${ID}" in
    debian)
      if ! echo "${REDIS_SUPPORTED_DEBIAN}" | grep -qw "${codename}"; then
        codename="bookworm"
      fi
      ;;
    ubuntu|*)
      if ! echo "${REDIS_SUPPORTED_UBUNTU}" | grep -qw "${codename}"; then
        codename="noble"
      fi
      ;;
  esac

  curl -fsSL https://packages.redis.io/gpg \
    | gpg --batch --yes --dearmor -o /etc/apt/keyrings/redis.gpg
  chmod 0644 /etc/apt/keyrings/redis.gpg

  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/redis.gpg] https://packages.redis.io/deb ${codename} main" \
    > /etc/apt/sources.list.d/redis.list

  apt-get update -y
  apt-get install -y --no-install-recommends redis

  SERVER_BIN="/usr/bin/redis-server"
  CLI_BIN="/usr/bin/redis-cli"
  SERVICE_USER="redis"
else
  # Valkey ships in Ubuntu 24.04+ and Debian trixie+. For older codenames,
  # fall back to building from the release tarball — but that's heavy. For
  # simplicity here, require a codename that ships valkey.
  apt-get install -y --no-install-recommends valkey-server valkey-tools || {
    echo "redis feature: ERROR — 'valkey-server' not available in this distro's apt index." >&2
    echo "  Use variant: redis, or switch to a base image with valkey-server in apt (Ubuntu 24.04+)." >&2
    exit 1
  }

  SERVER_BIN="/usr/bin/valkey-server"
  CLI_BIN="/usr/bin/valkey-cli"
  SERVICE_USER="valkey"

  # Compatibility symlinks so tools that hard-code redis-{server,cli} keep working.
  [ -e /usr/local/bin/redis-server ] || ln -sf "${SERVER_BIN}" /usr/local/bin/redis-server
  [ -e /usr/local/bin/redis-cli ]    || ln -sf "${CLI_BIN}"    /usr/local/bin/redis-cli
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

# Stop any auto-started daemon — dispatcher will handle.
service redis-server stop 2>/dev/null || true
service valkey stop 2>/dev/null || true
killall -q redis-server valkey-server 2>/dev/null || true

# --- config -----------------------------------------------------------------
install -d -m 0755 /etc/redis
install -d -m 0750 -o "${SERVICE_USER}" -g "${SERVICE_USER}" /var/lib/redis /var/log/redis

cat > /etc/redis/devcontainer.conf <<EOF
bind 127.0.0.1
protected-mode yes
port ${REDIS_PORT}
dir /var/lib/redis
appendonly yes
appendfsync everysec
loglevel notice
logfile /var/log/redis/server.log
daemonize no
EOF
if [ -n "${PASSWORD}" ]; then
  echo "requirepass ${PASSWORD}" >> /etc/redis/devcontainer.conf
fi
chmod 0644 /etc/redis/devcontainer.conf

# --- services dispatcher script ---------------------------------------------
install -d -m 0755 /etc/devcontainer-services.d

cat > /etc/devcontainer-services.d/30-redis.conf <<EOF
SERVER_BIN=$(printf '%q' "${SERVER_BIN}")
CLI_BIN=$(printf '%q' "${CLI_BIN}")
SERVICE_USER=$(printf '%q' "${SERVICE_USER}")
REDIS_PORT=$(printf '%q' "${REDIS_PORT}")
PASSWORD=$(printf '%q' "${PASSWORD}")
EOF
chmod 0600 /etc/devcontainer-services.d/30-redis.conf

cat > /etc/devcontainer-services.d/30-redis.sh <<'EOF'
#!/usr/bin/env bash
# devcontainer service: redis
set -e

# shellcheck disable=SC1091
. /etc/devcontainer-services.d/30-redis.conf

install -d -m 0750 -o "${SERVICE_USER}" -g "${SERVICE_USER}" /var/lib/redis /var/log/redis
chown -R "${SERVICE_USER}:${SERVICE_USER}" /var/lib/redis /var/log/redis

# Skip if already running.
if [ -n "${PASSWORD}" ]; then
  if "${CLI_BIN}" -p "${REDIS_PORT}" -a "${PASSWORD}" --no-auth-warning ping 2>/dev/null | grep -q PONG; then
    exit 0
  fi
else
  if "${CLI_BIN}" -p "${REDIS_PORT}" ping 2>/dev/null | grep -q PONG; then
    exit 0
  fi
fi

nohup sudo -u "${SERVICE_USER}" "${SERVER_BIN}" /etc/redis/devcontainer.conf \
  > /var/log/redis/init.log 2>&1 &

ready=0
for _ in $(seq 1 60); do
  if [ -n "${PASSWORD}" ]; then
    "${CLI_BIN}" -p "${REDIS_PORT}" -a "${PASSWORD}" --no-auth-warning ping 2>/dev/null | grep -q PONG && { ready=1; break; }
  else
    "${CLI_BIN}" -p "${REDIS_PORT}" ping 2>/dev/null | grep -q PONG && { ready=1; break; }
  fi
  sleep 0.2
done
if [ "${ready}" -ne 1 ]; then
  echo "redis service: daemon failed to become ready (see /var/log/redis/init.log)" >&2
  exit 1
fi
EOF
chmod 0755 /etc/devcontainer-services.d/30-redis.sh

# --- entrypoint wrapper -----------------------------------------------------
cat > /usr/local/share/redis-init.sh <<'EOF'
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
chmod 0755 /usr/local/share/redis-init.sh

# --- profile.d export -------------------------------------------------------
cat > /etc/profile.d/devcontainer-redis.sh <<EOF
: "\${REDIS_HOST:=127.0.0.1}"
: "\${REDIS_PORT:=${REDIS_PORT}}"
export REDIS_HOST REDIS_PORT
EOF
chmod 0644 /etc/profile.d/devcontainer-redis.sh

# --- sanity -----------------------------------------------------------------
"${SERVER_BIN}" --version 2>&1 | head -n1 || true

echo "redis feature: done"
