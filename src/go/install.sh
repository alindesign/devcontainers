#!/usr/bin/env bash
# Feature: go
set -euo pipefail

GO_VERSION="${VERSION:-latest}"
INSTALL_TOOLS="${INSTALLTOOLS:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "go feature: must run as root" >&2
  exit 1
fi

detect_user() {
  if [ -n "${_REMOTE_USER:-}" ] && id -u "${_REMOTE_USER}" >/dev/null 2>&1; then
    echo "${_REMOTE_USER}"
    return
  fi
  for c in vscode node ubuntu devcontainer; do
    if id -u "${c}" >/dev/null 2>&1; then echo "${c}"; return; fi
  done
  echo "root"
}

USERNAME="$(detect_user)"
USER_GROUP="$(id -gn "${USERNAME}")"
echo "go feature: target user=${USERNAME} version=${GO_VERSION}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl git build-essential
apt-get clean
rm -rf /var/lib/apt/lists/*

# --- bootstrap mise ---------------------------------------------------------
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

# --- install Go via mise ----------------------------------------------------
GO_SPEC="go@${GO_VERSION}"
mise use --global "${GO_SPEC}"
mise install "${GO_SPEC}"

GO_BIN_DIR="$(mise where "${GO_SPEC}")/bin"
if [ ! -x "${GO_BIN_DIR}/go" ]; then
  echo "go feature: ERROR — could not resolve Go bin dir (${GO_BIN_DIR})" >&2
  exit 1
fi
echo "go feature: $("${GO_BIN_DIR}/go" version)"

# --- symlinks for non-login shells ------------------------------------------
for bin in go gofmt; do
  src="${GO_BIN_DIR}/${bin}"
  [ -x "${src}" ] && ln -sf "${src}" "/usr/local/bin/${bin}"
done

# --- optional `go install` tools --------------------------------------------
if [ -n "${INSTALL_TOOLS}" ] && [ "${USERNAME}" != "root" ]; then
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  install -d -o "${USERNAME}" -g "${USER_GROUP}" "${USER_HOME}/go/bin"
  # shellcheck disable=SC2086
  sudo -u "${USERNAME}" \
    HOME="${USER_HOME}" \
    PATH="${GO_BIN_DIR}:${USER_HOME}/go/bin:${PATH}" \
    GOPATH="${USER_HOME}/go" \
    "${GO_BIN_DIR}/go" install ${INSTALL_TOOLS}
fi

# --- permissions ------------------------------------------------------------
chown -R "${USERNAME}:${USER_GROUP}" "${MISE_DATA_DIR}"
chmod -R a+rwX "${MISE_DATA_DIR}"
find "${MISE_DATA_DIR}" -type d -exec chmod g+s {} +

# --- shell activation + GOPATH/bin on PATH ----------------------------------
ensure_line() {
  local file="$1" line="$2"
  touch "${file}"
  grep -qxF "${line}" "${file}" || echo "${line}" >> "${file}"
  chown "${USERNAME}:${USER_GROUP}" "${file}" 2>/dev/null || true
}

if [ "${USERNAME}" != "root" ]; then
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  for rc in "${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc"; do
    [ -f "${rc}" ] || { [ "${rc##*/}" = ".bashrc" ] || continue; }
    ensure_line "${rc}" "export MISE_DATA_DIR=\"${MISE_DATA_DIR}\""
    ensure_line "${rc}" "export PATH=\"\$HOME/go/bin:\$PATH\""
    case "${rc##*/}" in
      .bashrc) ensure_line "${rc}" 'eval "$(mise activate bash)"' ;;
      .zshrc)  ensure_line "${rc}" 'eval "$(mise activate zsh)"' ;;
    esac
  done
fi

echo "go feature: done"
