#!/usr/bin/env bash
# Feature: node
# Installs Node via mise into a shared MISE_DATA_DIR=/usr/local/share/mise
# and activates the requested package manager (pnpm by default).
set -euo pipefail

NODE_VERSION_INPUT="${VERSION:-lts}"
PACKAGE_MANAGER="${PACKAGEMANAGER:-pnpm}"
PACKAGE_MANAGER_VERSION="${PACKAGEMANAGERVERSION:-latest}"

case "${PACKAGE_MANAGER}" in
  pnpm|npm|yarn|none) ;;
  *)
    echo "node feature: invalid packageManager='${PACKAGE_MANAGER}' (expected pnpm|npm|yarn|none)" >&2
    exit 1
    ;;
esac

if [ "$(id -u)" -ne 0 ]; then
  echo "node feature: must run as root" >&2
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
echo "node feature: target user=${USERNAME} packageManager=${PACKAGE_MANAGER}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl git build-essential
apt-get clean
rm -rf /var/lib/apt/lists/*

# --- bootstrap mise (idempotent; the `mise` feature may have already done it)
export MISE_DATA_DIR="/usr/local/share/mise"
install -d -m 0775 "${MISE_DATA_DIR}"

if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh
fi

if [ ! -f /etc/profile.d/mise.sh ]; then
  cat > /etc/profile.d/mise.sh <<EOF
export MISE_DATA_DIR="${MISE_DATA_DIR}"
EOF
  chmod 0644 /etc/profile.d/mise.sh
fi

mise --version

# --- resolve & install Node via mise ----------------------------------------
case "${NODE_VERSION_INPUT}" in
  lts|LTS|"")          MISE_NODE_SPEC="node@lts" ;;
  latest|node|current) MISE_NODE_SPEC="node@latest" ;;
  *)                   MISE_NODE_SPEC="node@${NODE_VERSION_INPUT}" ;;
esac

mise use --global "${MISE_NODE_SPEC}"
mise install "${MISE_NODE_SPEC}"

NODE_BIN_DIR="$(mise where "${MISE_NODE_SPEC}")/bin"
if [ ! -x "${NODE_BIN_DIR}/node" ]; then
  echo "node feature: ERROR — could not resolve installed Node bin dir (${NODE_BIN_DIR})" >&2
  exit 1
fi
echo "node feature: node $("${NODE_BIN_DIR}/node" --version) installed via mise"

# --- package manager via corepack ------------------------------------------
# Only enable shims for the requested package manager so PATH stays
# predictable. `none` enables all shims and lets package.json#packageManager
# decide via corepack at runtime.
export PATH="${NODE_BIN_DIR}:${PATH}"
case "${PACKAGE_MANAGER}" in
  pnpm)
    corepack enable pnpm
    if [ "${PACKAGE_MANAGER_VERSION}" = "latest" ]; then
      corepack prepare pnpm@latest --activate
    else
      corepack prepare "pnpm@${PACKAGE_MANAGER_VERSION}" --activate
    fi
    ;;
  yarn)
    corepack enable yarn
    if [ "${PACKAGE_MANAGER_VERSION}" = "latest" ]; then
      corepack prepare yarn@stable --activate
    else
      corepack prepare "yarn@${PACKAGE_MANAGER_VERSION}" --activate
    fi
    ;;
  npm)
    : # npm ships with Node; do not enable pnpm/yarn shims.
    ;;
  none)
    corepack enable
    ;;
esac

# --- expose to PATH for non-login shells (RUN steps, CI) --------------------
for bin in node npm npx corepack pnpm pnpx yarn; do
  src="${NODE_BIN_DIR}/${bin}"
  if [ -x "${src}" ]; then
    ln -sf "${src}" "/usr/local/bin/${bin}"
  fi
done

# --- permissions on mise data dir (survives UID remap) ----------------------
chown -R "${USERNAME}:${USER_GROUP}" "${MISE_DATA_DIR}"
chmod -R a+rwX "${MISE_DATA_DIR}"
find "${MISE_DATA_DIR}" -type d -exec chmod g+s {} +

# --- per-user shell activation for mise -------------------------------------
ensure_line() {
  local file="$1" line="$2"
  touch "${file}"
  grep -qxF "${line}" "${file}" || echo "${line}" >> "${file}"
  chown "${USERNAME}:${USER_GROUP}" "${file}" 2>/dev/null || true
}

if [ "${USERNAME}" != "root" ]; then
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  ensure_line "${USER_HOME}/.bashrc" "export MISE_DATA_DIR=\"${MISE_DATA_DIR}\""
  ensure_line "${USER_HOME}/.bashrc" 'eval "$(mise activate bash)"'

  if [ -f "${USER_HOME}/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
    ensure_line "${USER_HOME}/.zshrc" "export MISE_DATA_DIR=\"${MISE_DATA_DIR}\""
    ensure_line "${USER_HOME}/.zshrc" 'eval "$(mise activate zsh)"'
  fi
fi

echo "node feature: done"
