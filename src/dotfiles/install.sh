#!/usr/bin/env bash
# Feature: dotfiles
# Installs zsh, starship, modern CLI tools, neovim, and a baseline git config
# for the remote user of a devcontainer.
set -euo pipefail

SET_DEFAULT_SHELL="${SETDEFAULTSHELL:-true}"
GIT_USER_NAME="${GITUSERNAME:-}"
GIT_USER_EMAIL="${GITUSEREMAIL:-}"
GIT_SIGNING_FORMAT="${GITSIGNINGFORMAT:-gpg}"
GIT_SIGNING_KEY="${GITSIGNINGKEY:-}"
INSTALL_NVIM="${INSTALLNVIM:-true}"
INSTALL_GH_CLI="${INSTALLGHCLI:-true}"
INSTALL_ATUIN="${INSTALLATUIN:-true}"
ATUIN_SYNC_ADDRESS="${ATUINSYNCADDRESS:-}"
INSTALL_TMUX_CONFIG="${INSTALLTMUXCONFIG:-true}"

case "${GIT_SIGNING_FORMAT}" in
  gpg|ssh|none) ;;
  *)
    echo "dotfiles feature: invalid gitSigningFormat='${GIT_SIGNING_FORMAT}' (expected gpg|ssh|none)" >&2
    exit 1
    ;;
esac

if [ "$(id -u)" -ne 0 ]; then
  echo "dotfiles feature: must run as root" >&2
  exit 1
fi

# Feature directory — devcontainer features are copied to a temp dir before
# install.sh runs, so resolving relative to BASH_SOURCE is the canonical way
# to locate sibling files (config/*).
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${FEATURE_DIR}/config"

# --- resolve remote user ----------------------------------------------------
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
if [ "${USERNAME}" = "root" ]; then
  USER_HOME="/root"
else
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
fi
USER_GROUP="$(id -gn "${USERNAME}")"
echo "dotfiles feature: target user=${USERNAME} home=${USER_HOME}"

# --- arch -------------------------------------------------------------------
arch="$(uname -m)"
case "${arch}" in
  x86_64|amd64) ARCH_MUSL="x86_64-unknown-linux-musl"; ARCH_GNU="x86_64-unknown-linux-gnu" ;;
  aarch64|arm64) ARCH_MUSL="aarch64-unknown-linux-musl"; ARCH_GNU="aarch64-unknown-linux-gnu" ;;
  *) echo "dotfiles feature: unsupported arch ${arch}" >&2; exit 1 ;;
esac

# --- apt packages -----------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
apt-get update -y

# Bootstrap deps needed to register the GitHub CLI apt repo before the main
# install pass below. Kept narrow to avoid pulling more than necessary up front.
if [ "${INSTALL_GH_CLI}" = "true" ]; then
  apt-get install -y --no-install-recommends curl ca-certificates gnupg
  install -d -m 0755 /etc/apt/keyrings
  GH_KEYRING=/etc/apt/keyrings/githubcli-archive-keyring.gpg
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "${GH_KEYRING}"
  chmod go+r "${GH_KEYRING}"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=${GH_KEYRING}] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
  apt-get update -y
fi

APT_PKGS=(
  zsh
  git
  curl
  ca-certificates
  unzip
  tar
  gzip
  less
  locales
  tzdata
  fzf
  fd-find
  ripgrep
  bat
  jq
  git-delta
  tmux
  htop
  python3
  python3-pip
)
if [ "${INSTALL_NVIM}" = "true" ]; then
  # LazyVim's nvim-treesitter compiles parsers on first run — needs a C
  # toolchain. Recent neovim comes from upstream tarball below, not apt.
  APT_PKGS+=(gcc make)
fi
if [ "${GIT_SIGNING_FORMAT}" = "gpg" ]; then
  APT_PKGS+=(gnupg2)
fi
if [ "${INSTALL_GH_CLI}" = "true" ]; then
  APT_PKGS+=(gh)
fi

apt-get install -y --no-install-recommends "${APT_PKGS[@]}"

# Debian/Ubuntu ship fd as `fdfind` and bat as `batcat`. Add stable names.
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  ln -sf "$(command -v batcat)" /usr/local/bin/bat
fi

# Ensure UTF-8 locale (needed for fzf, nvim, starship glyphs)
if ! locale -a | grep -qi 'en_US\.utf8'; then
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
  locale-gen en_US.UTF-8
fi

# --- binary installs (not in apt or out of date) ----------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

install_starship() {
  if command -v starship >/dev/null 2>&1; then return; fi
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir /usr/local/bin
}

# Pinned versions — upstream installers query the GitHub API and hit
# unauthenticated rate limits in CI runners; direct downloads avoid that.
EZA_VERSION="0.20.10"
ZOXIDE_VERSION="0.9.6"
ATUIN_VERSION="18.16.1"
NEOVIM_VERSION="0.12.2"

install_eza() {
  if command -v eza >/dev/null 2>&1; then return; fi
  local url="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${ARCH_GNU}.tar.gz"
  curl -fsSL "${url}" | tar -xz -C "${TMP}"
  install -m 0755 "${TMP}/eza" /usr/local/bin/eza
}

install_zoxide() {
  if command -v zoxide >/dev/null 2>&1; then return; fi
  local url="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${ARCH_MUSL}.tar.gz"
  curl -fsSL "${url}" | tar -xz -C "${TMP}"
  install -m 0755 "${TMP}/zoxide" /usr/local/bin/zoxide
}

install_atuin() {
  if command -v atuin >/dev/null 2>&1; then return; fi
  local subdir="atuin-${ARCH_MUSL}"
  local url="https://github.com/atuinsh/atuin/releases/download/v${ATUIN_VERSION}/${subdir}.tar.gz"
  curl -fsSL "${url}" | tar -xz -C "${TMP}"
  install -m 0755 "${TMP}/${subdir}/atuin" /usr/local/bin/atuin
}

# Neovim from upstream tarball — apt's nvim on Ubuntu LTS is too old for
# LazyVim (LazyVim requires >= 0.10; jammy ships 0.6).
install_neovim_tarball() {
  local nv_arch
  case "${arch}" in
    x86_64|amd64) nv_arch="x86_64" ;;
    aarch64|arm64) nv_arch="arm64" ;;
  esac
  local subdir="nvim-linux-${nv_arch}"
  local url="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/${subdir}.tar.gz"
  # Drop any previously installed nvim (e.g. from a re-run with minimal)
  rm -rf "/opt/${subdir}"
  curl -fsSL "${url}" | tar -xz -C /opt
  ln -sf "/opt/${subdir}/bin/nvim" /usr/local/bin/nvim
}

install_starship
install_eza
install_zoxide
if [ "${INSTALL_ATUIN}" = "true" ]; then
  install_atuin
fi
if [ "${INSTALL_NVIM}" = "true" ]; then
  install_neovim_tarball
fi

# --- config files (copied from sibling config/ directory) -------------------
install_user_file() {
  local src="$1" dest="$2"
  local dir
  dir="$(dirname "${dest}")"
  install -d -o "${USERNAME}" -g "${USER_GROUP}" "${dir}" 2>/dev/null \
    || install -d "${dir}"
  install -m 0644 "${src}" "${dest}"
  chown "${USERNAME}:${USER_GROUP}" "${dest}" 2>/dev/null || true
}

install_user_tree() {
  local src="$1" dest="$2"
  install -d -o "${USERNAME}" -g "${USER_GROUP}" "${dest}" 2>/dev/null \
    || install -d "${dest}"
  cp -R "${src}/." "${dest}/"
  chown -R "${USERNAME}:${USER_GROUP}" "${dest}" 2>/dev/null || true
}

install_user_file "${CONFIG_DIR}/starship.toml" "${USER_HOME}/.config/starship.toml"
install_user_file "${CONFIG_DIR}/zshenv"        "${USER_HOME}/.zshenv"
install_user_file "${CONFIG_DIR}/zshrc"         "${USER_HOME}/.zshrc"

# atuin config — only written if atuin is installed and no config exists yet,
# so user-provided customisations are preserved across container rebuilds.
ATUIN_CONFIG="${USER_HOME}/.config/atuin/config.toml"
if [ "${INSTALL_ATUIN}" = "true" ] && [ ! -f "${ATUIN_CONFIG}" ]; then
  install_user_file "${CONFIG_DIR}/atuin.toml" "${ATUIN_CONFIG}"
  if [ -n "${ATUIN_SYNC_ADDRESS}" ]; then
    # Replace the commented sync_address line with the real one. Anchored to
    # the start of line so we don't accidentally match commentary elsewhere.
    sed -i -E "s|^# sync_address = .*|sync_address = \"${ATUIN_SYNC_ADDRESS}\"|" "${ATUIN_CONFIG}"
  fi
fi

# tmux config — managed by the feature (overwrites). Mount your host
# ~/.tmux.conf via devcontainer.json `mounts` if you want full custom control.
# TPM (Tmux Plugin Manager) is bootstrapped here too so the catppuccin status
# line works on the very first attach — no `prefix + I` ritual required.
if [ "${INSTALL_TMUX_CONFIG}" = "true" ]; then
  install_user_file "${CONFIG_DIR}/tmux.conf" "${USER_HOME}/.tmux.conf"
  TPM_DIR="${USER_HOME}/.tmux/plugins/tpm"
  install -d -o "${USERNAME}" -g "${USER_GROUP}" "$(dirname "${TPM_DIR}")"
  if [ ! -d "${TPM_DIR}" ]; then
    sudo -u "${USERNAME}" git clone --depth=1 --quiet \
      https://github.com/tmux-plugins/tpm "${TPM_DIR}"
  fi
  # Pre-install the plugins declared in ~/.tmux.conf. install_plugins reads
  # the config + git-clones each `@plugin`, so we don't need a tmux server.
  sudo -u "${USERNAME}" env HOME="${USER_HOME}" \
    bash "${TPM_DIR}/bin/install_plugins" >/dev/null 2>&1 || \
    echo "dotfiles feature: TPM plugin pre-install failed; run prefix+I inside tmux to install manually"
fi

# nvim config — alindesign LazyVim setup, pre-baked under config/nvim-lazyvim
# in this feature so the container has the full editor setup the moment build
# finishes. Lazy.nvim still resolves plugins on first `:Lazy sync` (or first
# nvim start, since the user's lazy.lua auto-bootstraps).
if [ "${INSTALL_NVIM}" = "true" ]; then
  install_user_tree "${CONFIG_DIR}/nvim-lazyvim" "${USER_HOME}/.config/nvim"
fi

# --- gitconfig --------------------------------------------------------------
GITCONFIG="${USER_HOME}/.gitconfig"
if [ ! -f "${GITCONFIG}" ]; then
  {
    echo "[core]"
    echo "  autocrlf = input"
    echo "  pager = delta"
    echo "[init]"
    echo "  defaultBranch = main"
    echo "[pull]"
    echo "  rebase = true"
    echo "[merge]"
    echo "  conflictstyle = zdiff3"
    echo "[diff]"
    echo "  colorMoved = default"
    echo "[interactive]"
    echo "  diffFilter = delta --color-only"
    echo "[delta]"
    echo "  navigate = true"
    echo "  side-by-side = true"
    echo "  line-numbers = true"
    if [ "${INSTALL_GH_CLI}" = "true" ]; then
      echo "[credential \"https://github.com\"]"
      echo "  helper = !gh auth git-credential"
      echo "[credential \"https://gist.github.com\"]"
      echo "  helper = !gh auth git-credential"
    fi
  } > "${GITCONFIG}"
  chown "${USERNAME}:${USER_GROUP}" "${GITCONFIG}" 2>/dev/null || true
elif [ "${INSTALL_GH_CLI}" = "true" ]; then
  # User-provided gitconfig already exists. Set the gh credential helpers
  # idempotently without clobbering anything else.
  sudo -u "${USERNAME}" git config --global credential.https://github.com.helper '!gh auth git-credential'
  sudo -u "${USERNAME}" git config --global credential.https://gist.github.com.helper '!gh auth git-credential'
fi
if [ -n "${GIT_USER_NAME}" ]; then
  sudo -u "${USERNAME}" git config --global user.name "${GIT_USER_NAME}"
fi
if [ -n "${GIT_USER_EMAIL}" ]; then
  sudo -u "${USERNAME}" git config --global user.email "${GIT_USER_EMAIL}"
fi

# --- commit signing ---------------------------------------------------------
ensure_line() {
  local file="$1" line="$2"
  touch "${file}"
  grep -qxF "${line}" "${file}" || echo "${line}" >> "${file}"
  chown "${USERNAME}:${USER_GROUP}" "${file}" 2>/dev/null || true
}

case "${GIT_SIGNING_FORMAT}" in
  gpg)
    # gnupg installed above; set up loopback pinentry so it works without TUI,
    # and export GPG_TTY in interactive shells so the agent can prompt.
    GNUPG_DIR="${USER_HOME}/.gnupg"
    install -d -m 0700 "${GNUPG_DIR}"
    chown "${USERNAME}:${USER_GROUP}" "${GNUPG_DIR}"
    GPG_CONF="${GNUPG_DIR}/gpg.conf"
    if ! grep -q '^pinentry-mode loopback' "${GPG_CONF}" 2>/dev/null; then
      echo 'pinentry-mode loopback' >> "${GPG_CONF}"
    fi
    GPG_AGENT_CONF="${GNUPG_DIR}/gpg-agent.conf"
    if ! grep -q '^allow-loopback-pinentry' "${GPG_AGENT_CONF}" 2>/dev/null; then
      echo 'allow-loopback-pinentry' >> "${GPG_AGENT_CONF}"
    fi
    chown -R "${USERNAME}:${USER_GROUP}" "${GNUPG_DIR}"
    chmod 0600 "${GPG_CONF}" "${GPG_AGENT_CONF}" 2>/dev/null || true

    # Export GPG_TTY so `gpg --sign` from interactive shells can find the tty.
    ensure_line "${USER_HOME}/.bashrc" 'export GPG_TTY=$(tty)'
    [ -f "${USER_HOME}/.zshrc" ] && ensure_line "${USER_HOME}/.zshrc" 'export GPG_TTY=$(tty)'

    if [ -n "${GIT_SIGNING_KEY}" ]; then
      sudo -u "${USERNAME}" git config --global user.signingkey "${GIT_SIGNING_KEY}"
      sudo -u "${USERNAME}" git config --global gpg.format openpgp
      sudo -u "${USERNAME}" git config --global commit.gpgsign true
      sudo -u "${USERNAME}" git config --global tag.gpgsign true
    fi
    ;;
  ssh)
    if [ -n "${GIT_SIGNING_KEY}" ]; then
      sudo -u "${USERNAME}" git config --global gpg.format ssh
      sudo -u "${USERNAME}" git config --global user.signingkey "${GIT_SIGNING_KEY}"
      sudo -u "${USERNAME}" git config --global commit.gpgsign true
      sudo -u "${USERNAME}" git config --global tag.gpgsign true
      # Point allowedSignersFile so `git log --show-signature` can verify.
      ensure_line "${USER_HOME}/.config/git/allowed_signers" ""
      sudo -u "${USERNAME}" git config --global gpg.ssh.allowedSignersFile "${USER_HOME}/.config/git/allowed_signers"
    fi
    ;;
  none)
    : # no signing setup
    ;;
esac

# --- default shell ----------------------------------------------------------
if [ "${SET_DEFAULT_SHELL}" = "true" ] && [ "${USERNAME}" != "root" ]; then
  ZSH_BIN="$(command -v zsh)"
  if [ -n "${ZSH_BIN}" ]; then
    if ! grep -qx "${ZSH_BIN}" /etc/shells; then
      echo "${ZSH_BIN}" >> /etc/shells
    fi
    chsh -s "${ZSH_BIN}" "${USERNAME}" || usermod -s "${ZSH_BIN}" "${USERNAME}"
  fi
fi

# --- cleanup ----------------------------------------------------------------
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "dotfiles feature: done"
