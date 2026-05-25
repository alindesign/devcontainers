#!/usr/bin/env bash
# Feature: python
# Installs Python via mise and activates the requested package manager
# (uv by default; poetry or none/pip supported).
set -euo pipefail

PY_VERSION_INPUT="${VERSION:-latest}"
PACKAGE_MANAGER="${PACKAGEMANAGER:-uv}"
PACKAGE_MANAGER_VERSION="${PACKAGEMANAGERVERSION:-latest}"

case "${PACKAGE_MANAGER}" in
  uv|poetry|none) ;;
  *)
    echo "python feature: invalid packageManager='${PACKAGE_MANAGER}' (expected uv|poetry|none)" >&2
    exit 1
    ;;
esac

if [ "$(id -u)" -ne 0 ]; then
  echo "python feature: must run as root" >&2
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
echo "python feature: target user=${USERNAME} packageManager=${PACKAGE_MANAGER} version=${PY_VERSION_INPUT}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
# Build-essential + libs Python expects when building from source via mise
# (mise prefers prebuilt binaries when available, but include deps for fallback).
apt-get install -y --no-install-recommends \
  ca-certificates curl git build-essential \
  libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
apt-get clean
rm -rf /var/lib/apt/lists/*

# --- bootstrap mise ---------------------------------------------------------
export MISE_DATA_DIR="/usr/local/share/mise"
install -d -m 0775 "${MISE_DATA_DIR}"

if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh
fi

# System-wide pin so shims work for every user, not just root.
install -d -m 0755 /etc/mise
if [ ! -f /etc/mise/config.toml ]; then
  printf '[tools]\n' > /etc/mise/config.toml
fi

case "${PY_VERSION_INPUT}" in
  latest|"") PY_TOOL_VAL="latest" ;;
  *)         PY_TOOL_VAL="${PY_VERSION_INPUT}" ;;
esac

if grep -q '^python = ' /etc/mise/config.toml; then
  sed -i "s|^python = .*|python = \"${PY_TOOL_VAL}\"|" /etc/mise/config.toml
else
  sed -i "/^\[tools\]/a python = \"${PY_TOOL_VAL}\"" /etc/mise/config.toml
fi
chmod 0644 /etc/mise/config.toml

PY_SPEC="python@${PY_TOOL_VAL}"
mise install "${PY_SPEC}"

PYTHON_BIN="$(mise which python 2>/dev/null || mise which python3)"
if [ -z "${PYTHON_BIN}" ] || [ ! -x "${PYTHON_BIN}" ]; then
  echo "python feature: ERROR — mise could not resolve 'python' binary" >&2
  exit 1
fi
PYTHON_BIN_DIR="$(dirname "${PYTHON_BIN}")"
echo "python feature: $("${PYTHON_BIN}" --version)"

# --- mise shims on PATH (system-wide) ---------------------------------------
mise reshim
SHIMS_DIR="${MISE_DATA_DIR}/shims"
cat > /etc/profile.d/mise.sh <<EOF
export MISE_DATA_DIR="${MISE_DATA_DIR}"
export PATH="${SHIMS_DIR}:\$PATH"
EOF
chmod 0644 /etc/profile.d/mise.sh

for bin in python python3 pip pip3; do
  src="${SHIMS_DIR}/${bin}"
  if [ -x "${src}" ]; then
    ln -sf "${src}" "/usr/local/bin/${bin}"
  fi
done

# --- package manager --------------------------------------------------------
case "${PACKAGE_MANAGER}" in
  uv)
    # uv installs into ${UV_INSTALL_DIR} as a single binary. Put it where
    # any user can find it on PATH without needing a profile.
    if [ "${PACKAGE_MANAGER_VERSION}" = "latest" ]; then
      curl -LsSf https://astral.sh/uv/install.sh \
        | env UV_INSTALL_DIR=/usr/local/bin UV_UNMANAGED_INSTALL=1 sh
    else
      curl -LsSf "https://astral.sh/uv/${PACKAGE_MANAGER_VERSION}/install.sh" \
        | env UV_INSTALL_DIR=/usr/local/bin UV_UNMANAGED_INSTALL=1 sh
    fi
    if [ ! -x /usr/local/bin/uv ]; then
      echo "python feature: ERROR — uv install did not place binary at /usr/local/bin/uv" >&2
      exit 1
    fi
    /usr/local/bin/uv --version
    ;;
  poetry)
    # Poetry's official installer wants its own venv. Put it under /usr/local
    # so it persists across container rebuilds.
    POETRY_HOME=/usr/local/poetry
    install -d -m 0755 "${POETRY_HOME}"
    if [ "${PACKAGE_MANAGER_VERSION}" = "latest" ]; then
      curl -sSL https://install.python-poetry.org \
        | POETRY_HOME="${POETRY_HOME}" "${PYTHON_BIN}" -
    else
      curl -sSL https://install.python-poetry.org \
        | POETRY_HOME="${POETRY_HOME}" POETRY_VERSION="${PACKAGE_MANAGER_VERSION}" "${PYTHON_BIN}" -
    fi
    ln -sf "${POETRY_HOME}/bin/poetry" /usr/local/bin/poetry
    /usr/local/bin/poetry --version
    ;;
  none)
    : # pip ships with the Python install via mise.
    ;;
esac

# --- permissions on mise data dir (survives UID remap) ----------------------
chown -R "${USERNAME}:${USER_GROUP}" "${MISE_DATA_DIR}"
chmod -R a+rwX "${MISE_DATA_DIR}"
find "${MISE_DATA_DIR}" -type d -exec chmod g+s {} +

# --- per-user shell hooks ---------------------------------------------------
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

echo "python feature: done"
