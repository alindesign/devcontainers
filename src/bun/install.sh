#!/usr/bin/env bash
# Feature: bun
# Installs Bun system-wide (single static binary). BUN_INSTALL points at
# /usr/local/bun so all users share the same install.
set -euo pipefail

BUN_VERSION="${VERSION:-latest}"

if [ "$(id -u)" -ne 0 ]; then
  echo "bun feature: must run as root" >&2
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
echo "bun feature: target user=${USERNAME} version=${BUN_VERSION}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl unzip
apt-get clean
rm -rf /var/lib/apt/lists/*

# --- install Bun into /usr/local/bun ---------------------------------------
export BUN_INSTALL=/usr/local/bun
install -d -m 0775 "${BUN_INSTALL}"

case "${BUN_VERSION}" in
  latest)  curl -fsSL https://bun.sh/install | env BUN_INSTALL="${BUN_INSTALL}" bash ;;
  canary)  curl -fsSL https://bun.sh/install | env BUN_INSTALL="${BUN_INSTALL}" bash -s -- --canary ;;
  *)       curl -fsSL https://bun.sh/install | env BUN_INSTALL="${BUN_INSTALL}" bash -s -- "bun-v${BUN_VERSION#v}" ;;
esac

if [ ! -x "${BUN_INSTALL}/bin/bun" ]; then
  echo "bun feature: ERROR — bun binary not found at ${BUN_INSTALL}/bin/bun after install" >&2
  ls -la "${BUN_INSTALL}/bin" 2>&1 || true
  exit 1
fi

# --- permissions (survives UID remap) ---------------------------------------
chown -R "${USERNAME}:${USER_GROUP}" "${BUN_INSTALL}"
chmod -R a+rwX "${BUN_INSTALL}"
find "${BUN_INSTALL}" -type d -exec chmod g+s {} +

# --- symlinks for non-login shells -----------------------------------------
ln -sf "${BUN_INSTALL}/bin/bun" /usr/local/bin/bun
ln -sf "${BUN_INSTALL}/bin/bun" /usr/local/bin/bunx

# --- profile.d + per-user activation ---------------------------------------
cat > /etc/profile.d/bun.sh <<EOF
export BUN_INSTALL="${BUN_INSTALL}"
export PATH="\$BUN_INSTALL/bin:\$PATH"
EOF
chmod 0644 /etc/profile.d/bun.sh

ensure_line() {
  local file="$1" line="$2"
  touch "${file}"
  grep -qxF "${line}" "${file}" || echo "${line}" >> "${file}"
  chown "${USERNAME}:${USER_GROUP}" "${file}" 2>/dev/null || true
}

if [ "${USERNAME}" != "root" ]; then
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  for rc in "${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc"; do
    [ -f "${rc}" ] || { [ "${rc##*/}" = ".bashrc" ] || continue; touch "${rc}"; }
    ensure_line "${rc}" "export BUN_INSTALL=\"${BUN_INSTALL}\""
    ensure_line "${rc}" "export PATH=\"\$BUN_INSTALL/bin:\$PATH\""
  done
fi

bun --version
echo "bun feature: done"
