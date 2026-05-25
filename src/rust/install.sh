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

# mise's rust plugin uses rustup under the hood and puts the real binaries in
# the rustup toolchain dir, not under `mise where`. Resolve via `mise which`.
RUSTC_BIN="$(mise which rustc 2>/dev/null || true)"
if [ -z "${RUSTC_BIN}" ] || [ ! -x "${RUSTC_BIN}" ]; then
  echo "rust feature: ERROR — mise could not resolve 'rustc' binary" >&2
  exit 1
fi
RUST_BIN_DIR="$(dirname "${RUSTC_BIN}")"
echo "rust feature: $("${RUSTC_BIN}" --version)"

# --- rustup components / targets --------------------------------------------
RUSTUP_BIN="$(mise which rustup 2>/dev/null || true)"
if [ -n "${RUSTUP_BIN}" ] && [ -x "${RUSTUP_BIN}" ]; then
  if [ -n "${COMPONENTS}" ]; then
    # shellcheck disable=SC2086
    "${RUSTUP_BIN}" component add ${COMPONENTS} || true
  fi
  if [ -n "${TARGETS}" ]; then
    # shellcheck disable=SC2086
    "${RUSTUP_BIN}" target add ${TARGETS} || true
  fi
fi

# --- mise shims on PATH (handles toolchain switches cleanly) ----------------
mise reshim
SHIMS_DIR="${MISE_DATA_DIR}/shims"
cat > /etc/profile.d/mise.sh <<EOF
export MISE_DATA_DIR="${MISE_DATA_DIR}"
export PATH="${SHIMS_DIR}:\$PATH"
EOF
chmod 0644 /etc/profile.d/mise.sh

for bin in rustc cargo rustup rustfmt clippy-driver cargo-clippy rust-analyzer; do
  src="${SHIMS_DIR}/${bin}"
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
