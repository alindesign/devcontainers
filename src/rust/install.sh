#!/usr/bin/env bash
# Feature: rust
set -euo pipefail

RUST_VERSION="${VERSION:-stable}"
COMPONENTS="${COMPONENTS:-clippy rustfmt rust-analyzer}"
TARGETS="${TARGETS:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "rust feature: must run as root" >&2
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
echo "rust feature: target user=${USERNAME} version=${RUST_VERSION}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl git build-essential pkg-config libssl-dev
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

# --- install Rust via mise --------------------------------------------------
RUST_SPEC="rust@${RUST_VERSION}"
mise use --global "${RUST_SPEC}"
mise install "${RUST_SPEC}"

RUST_BIN_DIR="$(mise where "${RUST_SPEC}")/bin"
if [ ! -x "${RUST_BIN_DIR}/rustc" ]; then
  echo "rust feature: ERROR — could not resolve Rust bin dir (${RUST_BIN_DIR})" >&2
  exit 1
fi
echo "rust feature: $("${RUST_BIN_DIR}/rustc" --version)"

# --- rustup components / targets --------------------------------------------
if command -v "${RUST_BIN_DIR}/rustup" >/dev/null 2>&1; then
  if [ -n "${COMPONENTS}" ]; then
    # shellcheck disable=SC2086
    "${RUST_BIN_DIR}/rustup" component add ${COMPONENTS} || true
  fi
  if [ -n "${TARGETS}" ]; then
    # shellcheck disable=SC2086
    "${RUST_BIN_DIR}/rustup" target add ${TARGETS} || true
  fi
fi

# --- symlinks ---------------------------------------------------------------
for bin in rustc cargo rustup rustfmt clippy-driver cargo-clippy rust-analyzer; do
  src="${RUST_BIN_DIR}/${bin}"
  [ -x "${src}" ] && ln -sf "${src}" "/usr/local/bin/${bin}"
done

# --- permissions ------------------------------------------------------------
chown -R "${USERNAME}:${USER_GROUP}" "${MISE_DATA_DIR}"
chmod -R a+rwX "${MISE_DATA_DIR}"
find "${MISE_DATA_DIR}" -type d -exec chmod g+s {} +

# --- shell activation -------------------------------------------------------
ensure_line() {
  local file="$1" line="$2"
  touch "${file}"
  grep -qxF "${line}" "${file}" || echo "${line}" >> "${file}"
  chown "${USERNAME}:${USER_GROUP}" "${file}" 2>/dev/null || true
}

if [ "${USERNAME}" != "root" ]; then
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  ensure_line "${USER_HOME}/.bashrc" "export MISE_DATA_DIR=\"${MISE_DATA_DIR}\""
  ensure_line "${USER_HOME}/.bashrc" "export PATH=\"\$HOME/.cargo/bin:\$PATH\""
  ensure_line "${USER_HOME}/.bashrc" 'eval "$(mise activate bash)"'

  if [ -f "${USER_HOME}/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
    ensure_line "${USER_HOME}/.zshrc" "export MISE_DATA_DIR=\"${MISE_DATA_DIR}\""
    ensure_line "${USER_HOME}/.zshrc" "export PATH=\"\$HOME/.cargo/bin:\$PATH\""
    ensure_line "${USER_HOME}/.zshrc" 'eval "$(mise activate zsh)"'
  fi
fi

echo "rust feature: done"
