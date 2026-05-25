#!/usr/bin/env bash
# Feature: dotfiles
# Installs zsh, starship, modern CLI tools, neovim, and a baseline git config
# for the remote user of a devcontainer.
set -euo pipefail

SET_DEFAULT_SHELL="${SETDEFAULTSHELL:-true}"
GIT_USER_NAME="${GITUSERNAME:-}"
GIT_USER_EMAIL="${GITUSEREMAIL:-}"
INSTALL_NVIM="${INSTALLNVIM:-true}"

if [ "$(id -u)" -ne 0 ]; then
  echo "dotfiles feature: must run as root" >&2
  exit 1
fi

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
echo "dotfiles feature: target user=${USERNAME} home=${USER_HOME}"

# --- arch -------------------------------------------------------------------
arch="$(uname -m)"
case "${arch}" in
  x86_64|amd64) ARCH_DEB="amd64"; ARCH_GH="x86_64"; ARCH_MUSL="x86_64-unknown-linux-musl"; ARCH_GNU="x86_64-unknown-linux-gnu" ;;
  aarch64|arm64) ARCH_DEB="arm64"; ARCH_GH="aarch64"; ARCH_MUSL="aarch64-unknown-linux-musl"; ARCH_GNU="aarch64-unknown-linux-gnu" ;;
  *) echo "dotfiles feature: unsupported arch ${arch}" >&2; exit 1 ;;
esac

# --- apt packages -----------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
apt-get update -y

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
  APT_PKGS+=(neovim)
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

install_eza() {
  if command -v eza >/dev/null 2>&1; then return; fi
  local url
  url="$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest \
    | jq -r --arg a "${ARCH_GNU}" '.assets[] | select(.name | endswith($a + ".tar.gz")) | .browser_download_url' \
    | head -n1)"
  if [ -z "${url}" ]; then
    echo "dotfiles feature: failed to resolve eza release for ${ARCH_GNU}" >&2
    return 1
  fi
  curl -fsSL "${url}" | tar -xz -C "${TMP}"
  install -m 0755 "${TMP}/eza" /usr/local/bin/eza
}

install_zoxide() {
  if command -v zoxide >/dev/null 2>&1; then return; fi
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
    | sh -s -- --bin-dir /usr/local/bin
}

install_starship
install_eza
install_zoxide

# --- config files (written to user home) ------------------------------------
write_user_file() {
  local path="$1"
  local content="$2"
  local dir
  dir="$(dirname "${path}")"
  install -d -o "${USERNAME}" -g "${USERNAME}" "${dir}" 2>/dev/null \
    || install -d "${dir}"
  printf '%s' "${content}" > "${path}"
  chown "${USERNAME}:$(id -gn "${USERNAME}")" "${path}" 2>/dev/null || true
}

# starship config
read -r -d '' STARSHIP_TOML <<'EOF' || true
add_newline = true
command_timeout = 1000

[character]
success_symbol = "[>](bold green)"
error_symbol = "[x](bold red)"

[directory]
truncation_length = 4
truncate_to_repo = true

[git_branch]
symbol = " "

[nodejs]
format = "[$symbol($version )]($style)"
symbol = "node "

[package]
disabled = true
EOF
write_user_file "${USER_HOME}/.config/starship.toml" "${STARSHIP_TOML}"

# zshrc
read -r -d '' ZSHRC <<'EOF' || true
# Managed by alindesign/devcontainers dotfiles feature.
# Local overrides go in ~/.zshrc.local (sourced at the end).

export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"
export PAGER="${PAGER:-less}"
export LESS="-R"
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# Completion
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Key bindings
bindkey -e
bindkey '^R' history-incremental-search-backward

# Aliases
alias ls='eza --group-directories-first'
alias ll='eza -lah --group-directories-first --git'
alias la='eza -a --group-directories-first'
alias lt='eza --tree --level=2 --group-directories-first'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias vim='nvim'
alias vi='nvim'

# fzf
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

# starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# mise — populated by node/go/rust/java features when installed.
export MISE_DATA_DIR="${MISE_DATA_DIR:-/usr/local/share/mise}"
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

# Local overrides
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
EOF
write_user_file "${USER_HOME}/.zshrc" "${ZSHRC}"

# gitconfig — only write if user did not already provide one
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
  } > "${GITCONFIG}"
  chown "${USERNAME}:$(id -gn "${USERNAME}")" "${GITCONFIG}" 2>/dev/null || true
fi
if [ -n "${GIT_USER_NAME}" ]; then
  sudo -u "${USERNAME}" git config --global user.name "${GIT_USER_NAME}"
fi
if [ -n "${GIT_USER_EMAIL}" ]; then
  sudo -u "${USERNAME}" git config --global user.email "${GIT_USER_EMAIL}"
fi

# nvim minimal config
if [ "${INSTALL_NVIM}" = "true" ]; then
  read -r -d '' NVIM_INIT <<'EOF' || true
-- Managed by alindesign/devcontainers dotfiles feature.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 4
vim.g.mapleader = " "
EOF
  write_user_file "${USER_HOME}/.config/nvim/init.lua" "${NVIM_INIT}"
fi

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
