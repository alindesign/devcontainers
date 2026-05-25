#!/usr/bin/env bash
# Feature: java
set -euo pipefail

JAVA_VERSION="${VERSION:-temurin-21}"
INSTALL_MAVEN="${INSTALLMAVEN:-false}"
INSTALL_GRADLE="${INSTALLGRADLE:-false}"

if [ "$(id -u)" -ne 0 ]; then
  echo "java feature: must run as root" >&2
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
echo "java feature: target user=${USERNAME} version=${JAVA_VERSION}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl git unzip zip
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

# --- install Java ----------------------------------------------------------
JAVA_SPEC="java@${JAVA_VERSION}"
mise use --global "${JAVA_SPEC}"
mise install "${JAVA_SPEC}"

JAVA_HOME_DIR="$(mise where "${JAVA_SPEC}")"
if [ ! -x "${JAVA_HOME_DIR}/bin/java" ]; then
  echo "java feature: ERROR — could not resolve Java install dir (${JAVA_HOME_DIR})" >&2
  exit 1
fi
echo "java feature: $("${JAVA_HOME_DIR}/bin/java" --version | head -n1)"

for bin in java javac jar jshell; do
  src="${JAVA_HOME_DIR}/bin/${bin}"
  [ -x "${src}" ] && ln -sf "${src}" "/usr/local/bin/${bin}"
done

# --- Maven / Gradle ---------------------------------------------------------
if [ "${INSTALL_MAVEN}" = "true" ]; then
  mise use --global maven@latest
  mise install maven@latest
  MAVEN_DIR="$(mise where maven@latest)"
  [ -x "${MAVEN_DIR}/bin/mvn" ] && ln -sf "${MAVEN_DIR}/bin/mvn" /usr/local/bin/mvn
fi

if [ "${INSTALL_GRADLE}" = "true" ]; then
  mise use --global gradle@latest
  mise install gradle@latest
  GRADLE_DIR="$(mise where gradle@latest)"
  [ -x "${GRADLE_DIR}/bin/gradle" ] && ln -sf "${GRADLE_DIR}/bin/gradle" /usr/local/bin/gradle
fi

# --- permissions ------------------------------------------------------------
chown -R "${USERNAME}:${USER_GROUP}" "${MISE_DATA_DIR}"
chmod -R a+rwX "${MISE_DATA_DIR}"
find "${MISE_DATA_DIR}" -type d -exec chmod g+s {} +

# --- JAVA_HOME + shell activation -------------------------------------------
cat > /etc/profile.d/java.sh <<EOF
export JAVA_HOME="${JAVA_HOME_DIR}"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF
chmod 0644 /etc/profile.d/java.sh

ensure_line() {
  local file="$1" line="$2"
  touch "${file}"
  grep -qxF "${line}" "${file}" || echo "${line}" >> "${file}"
  chown "${USERNAME}:${USER_GROUP}" "${file}" 2>/dev/null || true
}

if [ "${USERNAME}" != "root" ]; then
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  ensure_line "${USER_HOME}/.bashrc" "export MISE_DATA_DIR=\"${MISE_DATA_DIR}\""
  ensure_line "${USER_HOME}/.bashrc" "export JAVA_HOME=\"${JAVA_HOME_DIR}\""
  ensure_line "${USER_HOME}/.bashrc" 'eval "$(mise activate bash)"'

  if [ -f "${USER_HOME}/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
    ensure_line "${USER_HOME}/.zshrc" "export MISE_DATA_DIR=\"${MISE_DATA_DIR}\""
    ensure_line "${USER_HOME}/.zshrc" "export JAVA_HOME=\"${JAVA_HOME_DIR}\""
    ensure_line "${USER_HOME}/.zshrc" 'eval "$(mise activate zsh)"'
  fi
fi

echo "java feature: done"
