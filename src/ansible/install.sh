#!/usr/bin/env bash
# Feature: ansible
# Installs Ansible (and optionally ansible-lint) via `uv tool install`,
# falling back to pipx. Auto-bootstraps Python + uv if none is present.
set -euo pipefail

ANSIBLE_VERSION="${VERSION:-latest}"
INSTALL_LINT="${INSTALLLINT:-true}"
EXTRA_COLLECTIONS="${EXTRACOLLECTIONS:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "ansible feature: must run as root" >&2
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
echo "ansible feature: target user=${USERNAME} version=${ANSIBLE_VERSION}"

# Pick up Python from existing profile snippets if other features installed it.
# shellcheck disable=SC1091
[ -f /etc/profile.d/mise.sh ] && . /etc/profile.d/mise.sh
export PATH="/usr/local/bin:${PATH}"

# --- bootstrap Python + uv if missing --------------------------------------
if ! command -v python3 >/dev/null 2>&1 || ! command -v uv >/dev/null 2>&1; then
  echo "ansible feature: bootstrapping Python + uv (no compatible Python/uv on PATH)"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y --no-install-recommends \
    ca-certificates curl git build-essential \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev
  apt-get clean
  rm -rf /var/lib/apt/lists/*

  export MISE_DATA_DIR="/usr/local/share/mise"
  install -d -m 0775 "${MISE_DATA_DIR}"

  if ! command -v mise >/dev/null 2>&1; then
    curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh
  fi

  install -d -m 0755 /etc/mise
  if [ ! -f /etc/mise/config.toml ]; then
    printf '[tools]\n' > /etc/mise/config.toml
  fi
  if ! grep -q '^python = ' /etc/mise/config.toml; then
    sed -i '/^\[tools\]/a python = "latest"' /etc/mise/config.toml
  fi
  chmod 0644 /etc/mise/config.toml

  mise install python@latest
  mise reshim

  SHIMS_DIR="${MISE_DATA_DIR}/shims"
  cat > /etc/profile.d/mise.sh <<EOF
export MISE_DATA_DIR="${MISE_DATA_DIR}"
export PATH="${SHIMS_DIR}:\$PATH"
EOF
  chmod 0644 /etc/profile.d/mise.sh

  for bin in python python3 pip pip3; do
    src="${SHIMS_DIR}/${bin}"
    [ -x "${src}" ] && ln -sf "${src}" "/usr/local/bin/${bin}"
  done

  if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh \
      | env UV_INSTALL_DIR=/usr/local/bin UV_UNMANAGED_INSTALL=1 sh
  fi

  chown -R "${USERNAME}:${USER_GROUP}" "${MISE_DATA_DIR}"
  chmod -R a+rwX "${MISE_DATA_DIR}"
  find "${MISE_DATA_DIR}" -type d -exec chmod g+s {} +
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ansible feature: ERROR — python3 still missing after bootstrap" >&2
  exit 1
fi
echo "ansible feature: using $(python3 --version)"

# --- install Ansible -------------------------------------------------------
# uv tool install puts each tool in its own venv under UV_TOOL_DIR. Pin to
# /usr/local/share/uv so the install is system-wide and survives UID remap.
export UV_TOOL_DIR=/usr/local/share/uv/tools
export UV_TOOL_BIN_DIR=/usr/local/bin
install -d -m 0775 "${UV_TOOL_DIR}"

build_spec() {
  local pkg="$1"
  if [ "${ANSIBLE_VERSION}" = "latest" ] || [ "${pkg}" != "ansible" ]; then
    echo "${pkg}"
  else
    echo "${pkg}==${ANSIBLE_VERSION}"
  fi
}

if command -v uv >/dev/null 2>&1; then
  uv tool install --force "$(build_spec ansible)"
  if [ "${INSTALL_LINT}" = "true" ]; then
    uv tool install --force "$(build_spec ansible-lint)"
  fi
elif command -v pipx >/dev/null 2>&1; then
  pipx install --force "$(build_spec ansible)"
  if [ "${INSTALL_LINT}" = "true" ]; then
    pipx install --force "$(build_spec ansible-lint)"
  fi
else
  echo "ansible feature: ERROR — neither uv nor pipx available after bootstrap" >&2
  exit 1
fi

# Ensure ansible bin is on PATH for non-login shells.
for bin in ansible ansible-playbook ansible-galaxy ansible-vault ansible-config ansible-doc ansible-inventory ansible-lint; do
  for candidate in \
    "/usr/local/bin/${bin}" \
    "${UV_TOOL_DIR}/ansible/bin/${bin}" \
    "${UV_TOOL_DIR}/ansible-lint/bin/${bin}"; do
    if [ -x "${candidate}" ] && [ "${candidate}" != "/usr/local/bin/${bin}" ]; then
      ln -sf "${candidate}" "/usr/local/bin/${bin}"
      break
    fi
  done
done

ansible --version | head -n1

# --- optional Galaxy collections --------------------------------------------
if [ -n "${EXTRA_COLLECTIONS}" ] && [ "${USERNAME}" != "root" ]; then
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  # shellcheck disable=SC2086
  sudo -u "${USERNAME}" HOME="${USER_HOME}" \
    ansible-galaxy collection install ${EXTRA_COLLECTIONS} || true
fi

# --- permissions on uv tool dir (survives UID remap) -----------------------
chown -R "${USERNAME}:${USER_GROUP}" "${UV_TOOL_DIR}" 2>/dev/null || true
chmod -R a+rwX "${UV_TOOL_DIR}"
find "${UV_TOOL_DIR}" -type d -exec chmod g+s {} +

echo "ansible feature: done"
