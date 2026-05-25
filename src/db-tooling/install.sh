#!/usr/bin/env bash
# Feature: db-tooling
# Installs CLI clients (no servers) for the common dbs: postgres, mysql,
# redis, mongodb. Each can be skipped via skipX options.
set -euo pipefail

SKIP_POSTGRES="${SKIPPOSTGRES:-false}"
SKIP_MYSQL="${SKIPMYSQL:-false}"
SKIP_REDIS="${SKIPREDIS:-false}"
SKIP_MONGOSH="${SKIPMONGOSH:-false}"

if [ "$(id -u)" -ne 0 ]; then
  echo "db-tooling feature: must run as root" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl gnupg

PKGS=()
if [ "${SKIP_POSTGRES}" != "true" ]; then PKGS+=(postgresql-client); fi
if [ "${SKIP_MYSQL}"    != "true" ]; then PKGS+=(default-mysql-client); fi
if [ "${SKIP_REDIS}"    != "true" ]; then PKGS+=(redis-tools); fi

if [ "${#PKGS[@]}" -gt 0 ]; then
  apt-get install -y --no-install-recommends "${PKGS[@]}"
fi

# --- mongosh (Mongo's official apt repo) -----------------------------------
if [ "${SKIP_MONGOSH}" != "true" ]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  arch="$(dpkg --print-architecture)"
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
    | gpg --batch --yes --dearmor -o /etc/apt/keyrings/mongodb-server-7.0.gpg
  chmod 0644 /etc/apt/keyrings/mongodb-server-7.0.gpg

  # mongosh apt repo only ships a fixed set of Ubuntu codenames and lags
  # behind interim releases (e.g. 25.04 'plucky', 25.10 'resolute' are absent).
  # Map every unknown distro to the latest LTS the repo supports.
  MONGO_SUPPORTED="noble jammy focal"
  codename="${VERSION_CODENAME:-noble}"
  if ! echo "${MONGO_SUPPORTED}" | grep -qw "${codename}"; then
    echo "db-tooling feature: '${codename}' has no MongoDB apt channel; falling back to noble"
    codename="noble"
  fi
  case "${ID}" in
    debian)
      # MongoDB doesn't publish Debian repos for newer codenames cleanly;
      # use a recent Ubuntu LTS.
      case "${VERSION_CODENAME}" in
        bookworm|trixie) codename="jammy" ;;
        bullseye)        codename="focal" ;;
      esac
      ;;
  esac

  echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/ubuntu ${codename}/mongodb-org/7.0 multiverse" \
    > /etc/apt/sources.list.d/mongodb-org-7.0.list

  apt-get update -y
  apt-get install -y --no-install-recommends mongodb-mongosh
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

# --- sanity (head + pipefail can trip SIGPIPE; guard each print) -----------
[ "${SKIP_POSTGRES}" = "true" ] || psql --version 2>&1 | head -n1 || true
[ "${SKIP_MYSQL}"    = "true" ] || mysql --version 2>&1 | head -n1 || true
[ "${SKIP_REDIS}"    = "true" ] || redis-cli --version 2>&1 | head -n1 || true
[ "${SKIP_MONGOSH}"  = "true" ] || mongosh --version 2>&1 | head -n1 || true

echo "db-tooling feature: done"
