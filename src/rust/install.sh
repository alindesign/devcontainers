#!/usr/bin/env bash
# Feature: rust
# Installs Rust via rustup directly (not via mise — the mise rust plugin
# delegates to rustup but stores the toolchain under the invoking user's HOME,
# which doesn't survive across container users). RUSTUP_HOME / CARGO_HOME are
# pinned system-wide so all users in the container share the same toolchain.
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
    echo "${_REMOTE_USER}"; return
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

# --- shared rustup root -----------------------------------------------------
export RUSTUP_HOME=/usr/local/rustup
export CARGO_HOME=/usr/local/cargo
install -d -m 0775 "${RUSTUP_HOME}" "${CARGO_HOME}"
chown -R "${USERNAME}:${USER_GROUP}" "${RUSTUP_HOME}" "${CARGO_HOME}"

# --- install rustup as the remote user --------------------------------------
sudo -u "${USERNAME}" \
  HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)" \
  RUSTUP_HOME="${RUSTUP_HOME}" \
  CARGO_HOME="${CARGO_HOME}" \
  bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain ${RUST_VERSION} --profile minimal"

if [ ! -x "${CARGO_HOME}/bin/rustc" ]; then
  echo "rust feature: ERROR — rustc not found at ${CARGO_HOME}/bin/rustc after rustup install" >&2
  ls -la "${CARGO_HOME}/bin" 2>&1 || true
  exit 1
fi
echo "rust feature: $("${CARGO_HOME}/bin/rustc" --version)"

# --- components / targets ---------------------------------------------------
if [ -n "${COMPONENTS}" ]; then
  # shellcheck disable=SC2086
  sudo -u "${USERNAME}" \
    HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)" \
    RUSTUP_HOME="${RUSTUP_HOME}" CARGO_HOME="${CARGO_HOME}" \
    "${CARGO_HOME}/bin/rustup" component add ${COMPONENTS} || true
fi
if [ -n "${TARGETS}" ]; then
  # shellcheck disable=SC2086
  sudo -u "${USERNAME}" \
    HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)" \
    RUSTUP_HOME="${RUSTUP_HOME}" CARGO_HOME="${CARGO_HOME}" \
    "${CARGO_HOME}/bin/rustup" target add ${TARGETS} || true
fi

# --- permissions ------------------------------------------------------------
chmod -R a+rwX "${RUSTUP_HOME}" "${CARGO_HOME}"
find "${RUSTUP_HOME}" "${CARGO_HOME}" -type d -exec chmod g+s {} +

# --- expose to PATH globally ------------------------------------------------
cat > /etc/profile.d/rust.sh <<EOF
export RUSTUP_HOME="${RUSTUP_HOME}"
export CARGO_HOME="${CARGO_HOME}"
export PATH="${CARGO_HOME}/bin:\$PATH"
EOF
chmod 0644 /etc/profile.d/rust.sh

for bin in cargo rustc rustup rustfmt clippy-driver cargo-clippy rust-analyzer; do
  src="${CARGO_HOME}/bin/${bin}"
  [ -x "${src}" ] && ln -sf "${src}" "/usr/local/bin/${bin}"
done

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
    [ -f "${rc}" ] || { [ "${rc##*/}" = ".bashrc" ] || continue; touch "${rc}"; }
    ensure_line "${rc}" "export RUSTUP_HOME=\"${RUSTUP_HOME}\""
    ensure_line "${rc}" "export CARGO_HOME=\"${CARGO_HOME}\""
    ensure_line "${rc}" "export PATH=\"${CARGO_HOME}/bin:\$PATH\""
  done
fi

echo "rust feature: done"
