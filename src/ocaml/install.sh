#!/usr/bin/env bash
# Feature: ocaml
# Installs opam + an OCaml compiler switch into a shared OPAMROOT.
set -euo pipefail

OCAML_VERSION="${VERSION:-5.2.0}"
INSTALL_DUNE_LSP="${INSTALLDUNEANDLSP:-true}"

if [ "$(id -u)" -ne 0 ]; then
  echo "ocaml feature: must run as root" >&2
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
echo "ocaml feature: target user=${USERNAME} version=${OCAML_VERSION}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
# opam compile deps (build-essential, m4, etc.) + bubblewrap for sandboxing
apt-get install -y --no-install-recommends \
  ca-certificates curl git build-essential m4 unzip patch \
  bubblewrap pkg-config
apt-get clean
rm -rf /var/lib/apt/lists/*

# --- install opam binary ----------------------------------------------------
arch="$(uname -m)"
case "${arch}" in
  x86_64|amd64)  OPAM_ARCH="x86_64" ;;
  aarch64|arm64) OPAM_ARCH="arm64"  ;;
  *) echo "ocaml feature: unsupported arch ${arch}" >&2; exit 1 ;;
esac

if ! command -v opam >/dev/null 2>&1; then
  OPAM_VERSION="2.2.1"
  curl -fsSL "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-${OPAM_VERSION}-${OPAM_ARCH}-linux" \
    -o /usr/local/bin/opam
  chmod 0755 /usr/local/bin/opam
fi
opam --version

# --- shared opam root -------------------------------------------------------
export OPAMROOT="/usr/local/share/opam"
install -d -m 0775 "${OPAMROOT}"
# opam init writes into OPAMROOT/opam-init/... as the invoking user, so the
# dir must already be writable by the remote user before we drop privileges.
chown -R "${USERNAME}:${USER_GROUP}" "${OPAMROOT}"
chmod -R a+rwX "${OPAMROOT}"

USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"

# Initialize as the remote user so the switch is owned correctly.
sudo -u "${USERNAME}" \
  HOME="${USER_HOME}" \
  OPAMROOT="${OPAMROOT}" \
  opam init --disable-sandboxing --bare --yes --no-setup

sudo -u "${USERNAME}" \
  HOME="${USER_HOME}" \
  OPAMROOT="${OPAMROOT}" \
  opam switch create default "ocaml-base-compiler.${OCAML_VERSION}" --yes

if [ "${INSTALL_DUNE_LSP}" = "true" ]; then
  sudo -u "${USERNAME}" \
    HOME="${USER_HOME}" \
    OPAMROOT="${OPAMROOT}" \
    bash -c 'eval "$(opam env --switch=default)"; opam install -y dune ocaml-lsp-server ocamlformat'
fi

# --- expose binaries --------------------------------------------------------
SWITCH_BIN="${OPAMROOT}/default/bin"
for bin in ocaml ocamlc ocamlopt ocamlfind dune ocaml-lsp-server ocamlformat utop; do
  src="${SWITCH_BIN}/${bin}"
  [ -x "${src}" ] && ln -sf "${src}" "/usr/local/bin/${bin}"
done

# --- permissions ------------------------------------------------------------
chown -R "${USERNAME}:${USER_GROUP}" "${OPAMROOT}"
chmod -R a+rwX "${OPAMROOT}"
find "${OPAMROOT}" -type d -exec chmod g+s {} +

# --- shell activation -------------------------------------------------------
cat > /etc/profile.d/opam.sh <<EOF
export OPAMROOT="${OPAMROOT}"
EOF
chmod 0644 /etc/profile.d/opam.sh

ensure_line() {
  local file="$1" line="$2"
  touch "${file}"
  grep -qxF "${line}" "${file}" || echo "${line}" >> "${file}"
  chown "${USERNAME}:${USER_GROUP}" "${file}" 2>/dev/null || true
}

if [ "${USERNAME}" != "root" ]; then
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  for rc in "${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc"; do
    ensure_line "${rc}" "export OPAMROOT=\"${OPAMROOT}\""
    ensure_line "${rc}" 'eval "$(opam env --switch=default 2>/dev/null)"'
  done
fi

echo "ocaml feature: done"
