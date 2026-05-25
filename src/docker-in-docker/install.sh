#!/usr/bin/env bash
# Feature: docker-in-docker
# Installs Docker Engine (CE) inside the container using Docker's official apt
# repo, plus buildx + compose v2. Daemon is started lazily via the
# /usr/local/share/docker-init.sh entrypoint on first container start.
set -euo pipefail

DOCKER_VERSION="${VERSION:-latest}"
INSTALL_BUILDX="${INSTALLBUILDX:-true}"
INSTALL_COMPOSE="${INSTALLCOMPOSE:-true}"
COMPOSE_VARIANT="${DOCKERDASHCOMPOSEVERSION:-v2}"

if [ "$(id -u)" -ne 0 ]; then
  echo "docker-in-docker feature: must run as root" >&2
  exit 1
fi

detect_user() {
  if [ -n "${_REMOTE_USER:-}" ] && id -u "${_REMOTE_USER}" >/dev/null 2>&1; then
    echo "${_REMOTE_USER}"; return
  fi
  for c in vscode node ubuntu devcontainer; do
    if id -u "${c}" >/dev/null 2>&1; then echo "${c}"; return; fi
  done
  echo "root"
}

USERNAME="$(detect_user)"
USER_GROUP="$(id -gn "${USERNAME}")"
echo "docker-in-docker feature: target user=${USERNAME}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release iptables uidmap pigz

# --- Docker official apt repo ----------------------------------------------
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
chmod 0644 /etc/apt/keyrings/docker.gpg

# shellcheck source=/dev/null
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y

PKGS=(docker-ce docker-ce-cli containerd.io)
if [ "${INSTALL_BUILDX}" = "true" ]; then PKGS+=(docker-buildx-plugin); fi
if [ "${INSTALL_COMPOSE}" = "true" ]; then PKGS+=(docker-compose-plugin); fi

if [ "${DOCKER_VERSION}" != "latest" ]; then
  # Resolve the apt version string for the requested major.minor (e.g. 24.0)
  full="$(apt-cache madison docker-ce | awk '{print $3}' | grep "^[0-9]*:${DOCKER_VERSION}" | head -n1 || true)"
  if [ -z "$full" ]; then
    echo "docker-in-docker feature: ERROR — no apt candidate for docker-ce ${DOCKER_VERSION}" >&2
    apt-cache madison docker-ce | head -n5 >&2 || true
    exit 1
  fi
  apt-get install -y --no-install-recommends docker-ce="${full}" docker-ce-cli="${full}" containerd.io
  if [ "${INSTALL_BUILDX}" = "true" ]; then apt-get install -y --no-install-recommends docker-buildx-plugin; fi
  if [ "${INSTALL_COMPOSE}" = "true" ]; then apt-get install -y --no-install-recommends docker-compose-plugin; fi
else
  apt-get install -y --no-install-recommends "${PKGS[@]}"
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

# --- legacy docker-compose shim --------------------------------------------
if [ "${INSTALL_COMPOSE}" = "true" ] && [ "${COMPOSE_VARIANT}" = "v2" ]; then
  # Provide `docker-compose` as a shim that delegates to `docker compose`.
  cat > /usr/local/bin/docker-compose <<'EOF'
#!/usr/bin/env sh
exec docker compose "$@"
EOF
  chmod 0755 /usr/local/bin/docker-compose
fi

# --- group + user setup ----------------------------------------------------
getent group docker >/dev/null || groupadd -r docker
if [ "${USERNAME}" != "root" ]; then
  usermod -aG docker "${USERNAME}" || true
fi

# --- docker daemon entrypoint ----------------------------------------------
cat > /usr/local/share/docker-init.sh <<'EOF'
#!/usr/bin/env bash
# Lazy-start dockerd at container boot. Re-entrant; idempotent.
set -e

start_dockerd() {
  if pgrep -x dockerd >/dev/null 2>&1; then return 0; fi
  mkdir -p /var/log /var/run
  ( dockerd > /var/log/dockerd.log 2>&1 ) &
  for _ in $(seq 1 30); do
    if docker info >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  echo "docker-in-docker: dockerd failed to become ready (see /var/log/dockerd.log)" >&2
  return 1
}

start_dockerd || true

# Hand off to the requested command (or sleep forever if none — matches
# devcontainers/docker-in-docker upstream behaviour).
if [ $# -gt 0 ]; then
  exec "$@"
else
  exec sleep infinity
fi
EOF
chmod 0755 /usr/local/share/docker-init.sh

echo "docker-in-docker feature: done"
