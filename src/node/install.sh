#!/usr/bin/env bash
# Feature: node
# Installs Node via nvm into a system-wide NVM_DIR=/usr/local/share/nvm
# and activates the requested package manager (pnpm by default).
set -euo pipefail

NODE_VERSION="${VERSION:-lts}"
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

# --- nvm (system-wide) ------------------------------------------------------
export NVM_DIR="/usr/local/share/nvm"
install -d -m 0775 "${NVM_DIR}"

if [ ! -s "${NVM_DIR}/nvm.sh" ]; then
  NVM_TAG="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  if [ -z "${NVM_TAG}" ]; then NVM_TAG="v0.40.1"; fi
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_TAG}/install.sh" \
    | PROFILE=/dev/null bash
fi

# shellcheck disable=SC1091
. "${NVM_DIR}/nvm.sh"

case "${NODE_VERSION}" in
  lts|LTS|"")          nvm install --lts --latest-npm; nvm alias default 'lts/*' ;;
  latest|node|current) nvm install node --latest-npm; nvm alias default node ;;
  *)                   nvm install "${NODE_VERSION}" --latest-npm; nvm alias default "${NODE_VERSION}" ;;
esac
nvm use default
NODE_CURRENT="$(nvm version default)"
echo "node feature: node ${NODE_CURRENT} installed"

# --- package manager via corepack ------------------------------------------
# Only enable shims for the requested package manager so PATH stays
# predictable. `none` enables all shims and lets package.json#packageManager
# decide via corepack at runtime.
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

# --- expose to PATH for login + non-login shells ----------------------------
PROFILE_SNIPPET="/etc/profile.d/nvm.sh"
cat > "${PROFILE_SNIPPET}" <<EOF
export NVM_DIR="${NVM_DIR}"
[ -s "\$NVM_DIR/nvm.sh" ] && \\. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \\. "\$NVM_DIR/bash_completion"
EOF
chmod 0644 "${PROFILE_SNIPPET}"

# Ensure non-interactive shells (RUN steps, scripts) find node/pm via symlinks.
NODE_BIN_DIR="$(dirname "$(nvm which default)")"
for bin in node npm npx corepack pnpm pnpx yarn; do
  src="${NODE_BIN_DIR}/${bin}"
  if [ -x "${src}" ]; then
    ln -sf "${src}" "/usr/local/bin/${bin}"
  fi
done

# Permissions: NVM_DIR is shared between root (build time) and the remote
# user (runtime). Some base images / devcontainer test harnesses remap the
# remote user's UID after this script runs (e.g. vscode 1000 -> 1001), which
# would orphan strict ownership. Make NVM_DIR world-readable/writable with
# setgid so any user can install additional Node versions — there are no
# secrets in here, only Node toolchains.
chown -R "${USERNAME}:${USER_GROUP}" "${NVM_DIR}"
chmod -R a+rwX "${NVM_DIR}"
find "${NVM_DIR}" -type d -exec chmod g+s {} +

# --- per-user shell hooks ---------------------------------------------------
ensure_line() {
  local file="$1" line="$2"
  touch "${file}"
  grep -qxF "${line}" "${file}" || echo "${line}" >> "${file}"
  chown "${USERNAME}:${USER_GROUP}" "${file}" 2>/dev/null || true
}

if [ "${USERNAME}" != "root" ]; then
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  for rc in "${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc"; do
    ensure_line "${rc}" "export NVM_DIR=\"${NVM_DIR}\""
    ensure_line "${rc}" '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
  done
fi

echo "node feature: done"
