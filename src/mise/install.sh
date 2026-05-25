#!/usr/bin/env bash
# Feature: mise
# Installs mise system-wide and sets up shared data dir + shell activation.
set -euo pipefail

MISE_VERSION="${VERSION:-latest}"
AUTO_ACTIVATE="${AUTOACTIVATE:-true}"

if [ "$(id -u)" -ne 0 ]; then
  echo "mise feature: must run as root" >&2
  exit 1
fi

detect_user() {
  if [ -n "${_REMOTE_USER:-}" ] && id -u "${_REMOTE_USER}" >/dev/null 2>&1; then
    echo "${_REMOTE_USER}"
    return
  fi
  for candidate in vscode node ubuntu devcontainer; do
    if id -u "${candidate}" >/dev/null 2>&1; then
      echo "${candidate}"
      return
    fi
  done
  echo "root"
}

USERNAME="$(detect_user)"
USER_GROUP="$(id -gn "${USERNAME}")"
echo "mise feature: target user=${USERNAME}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl git tar gzip xz-utils
apt-get clean
rm -rf /var/lib/apt/lists/*

# --- mise data dir (shared) -------------------------------------------------
MISE_DATA_DIR="/usr/local/share/mise"
install -d -m 0775 "${MISE_DATA_DIR}"

# --- arch + download --------------------------------------------------------
arch="$(uname -m)"
case "${arch}" in
  x86_64|amd64) MISE_ARCH="x64" ;;
  aarch64|arm64) MISE_ARCH="arm64" ;;
  *) echo "mise feature: unsupported arch ${arch}" >&2; exit 1 ;;
esac

if [ "${MISE_VERSION}" = "latest" ]; then
  MISE_URL="https://mise.run"
  curl -fsSL "${MISE_URL}" | MISE_INSTALL_PATH=/usr/local/bin/mise sh
else
  # Pinned version: download release artifact directly.
  TARBALL="mise-v${MISE_VERSION#v}-linux-${MISE_ARCH}.tar.gz"
  URL="https://github.com/jdx/mise/releases/download/v${MISE_VERSION#v}/${TARBALL}"
  TMP="$(mktemp -d)"
  curl -fsSL "${URL}" -o "${TMP}/mise.tar.gz"
  tar -xzf "${TMP}/mise.tar.gz" -C "${TMP}"
  install -m 0755 "${TMP}/mise/bin/mise" /usr/local/bin/mise
  rm -rf "${TMP}"
fi

mise --version

# --- permissions (survives UID remap; see node feature for rationale) -------
chown -R "${USERNAME}:${USER_GROUP}" "${MISE_DATA_DIR}"
chmod -R a+rwX "${MISE_DATA_DIR}"
find "${MISE_DATA_DIR}" -type d -exec chmod g+s {} +

# --- shell activation -------------------------------------------------------
# Always expose MISE_DATA_DIR via /etc/profile.d so all shells see the same
# shared toolchains, even from non-login RUN steps.
cat > /etc/profile.d/mise.sh <<EOF
export MISE_DATA_DIR="${MISE_DATA_DIR}"
EOF
chmod 0644 /etc/profile.d/mise.sh

if [ "${AUTO_ACTIVATE}" = "true" ] && [ "${USERNAME}" != "root" ]; then
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  ensure_line() {
    local file="$1" line="$2"
    touch "${file}"
    grep -qxF "${line}" "${file}" || echo "${line}" >> "${file}"
    chown "${USERNAME}:${USER_GROUP}" "${file}" 2>/dev/null || true
  }

  for rc in "${USER_HOME}/.bashrc"; do
    ensure_line "${rc}" "export MISE_DATA_DIR=\"${MISE_DATA_DIR}\""
    ensure_line "${rc}" 'eval "$(mise activate bash)"'
  done

  if [ -f "${USER_HOME}/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
    ensure_line "${USER_HOME}/.zshrc" "export MISE_DATA_DIR=\"${MISE_DATA_DIR}\""
    ensure_line "${USER_HOME}/.zshrc" 'eval "$(mise activate zsh)"'
  fi
fi

echo "mise feature: done"
