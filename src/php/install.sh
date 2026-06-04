#!/usr/bin/env bash
# Feature: php
# Installs PHP via the Sury repository (packages.sury.org/php/) with Composer,
# user-selected extensions, and opt-in Xdebug / FPM / Symfony CLI / Laravel
# installer.
set -euo pipefail

PHP_VERSION="${VERSION:-8.4}"
PHP_EXTENSIONS="${EXTENSIONS:-mbstring intl xml zip gd curl mysql pgsql opcache bcmath gmp}"
PHP_PECL="${PECL:-}"
INSTALL_COMPOSER="${INSTALLCOMPOSER:-true}"
INSTALL_XDEBUG="${INSTALLXDEBUG:-false}"
INSTALL_FPM="${INSTALLFPM:-false}"
INSTALL_SYMFONY_CLI="${INSTALLSYMFONYCLI:-false}"
INSTALL_LARAVEL_INSTALLER="${INSTALLLARAVELINSTALLER:-false}"
COMPOSER_PACKAGES="${COMPOSERPACKAGES:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "php feature: must run as root" >&2
  exit 1
fi

if ! echo "${PHP_VERSION}" | grep -Eq '^[0-9]+\.[0-9]+$'; then
  echo "php feature: invalid version '${PHP_VERSION}' (expected MAJOR.MINOR, e.g. '8.4')" >&2
  exit 1
fi

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
USER_GROUP="$(id -gn "${USERNAME}")"
echo "php feature: target user=${USERNAME} php=${PHP_VERSION} fpm=${INSTALL_FPM} xdebug=${INSTALL_XDEBUG}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release apt-transport-https

# --- Sury repo --------------------------------------------------------------
# shellcheck source=/dev/null
. /etc/os-release
ARCH="$(dpkg --print-architecture)"

# packages.sury.org/php publishes for current Debian + Ubuntu codenames
# including resolute (26.04). Fall back to the most recent LTS for unknown.
SURY_SUPPORTED_UBUNTU="resolute plucky noble jammy focal"
SURY_SUPPORTED_DEBIAN="trixie bookworm bullseye"
codename="${VERSION_CODENAME:-noble}"

case "${ID}" in
  debian)
    if ! echo "${SURY_SUPPORTED_DEBIAN}" | grep -qw "${codename}"; then
      echo "php feature: '${codename}' has no Sury Debian channel; falling back to bookworm"
      codename="bookworm"
    fi
    ;;
  ubuntu|*)
    if ! echo "${SURY_SUPPORTED_UBUNTU}" | grep -qw "${codename}"; then
      echo "php feature: '${codename}' has no Sury Ubuntu channel; falling back to noble"
      codename="noble"
    fi
    ;;
esac

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://packages.sury.org/php/apt.gpg \
  | gpg --batch --yes --dearmor -o /etc/apt/keyrings/sury-php.gpg
chmod 0644 /etc/apt/keyrings/sury-php.gpg

echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${codename} main" \
  > /etc/apt/sources.list.d/sury-php.list

apt-get update -y

# --- assemble package list --------------------------------------------------
# Sanitize extensions: trim, lowercase, dedup, reject anything not [a-z0-9_-].
sanitize_extensions() {
  local input="$1" out=()
  # shellcheck disable=SC2206
  local toks=( ${input//,/ } )
  local seen=" "
  for t in "${toks[@]}"; do
    t="$(echo "${t}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    [ -z "${t}" ] && continue
    if ! echo "${t}" | grep -Eq '^[a-z0-9_-]+$'; then
      echo "php feature: WARN — skipping invalid extension token '${t}'" >&2
      continue
    fi
    case "${seen}" in *" ${t} "*) continue ;; esac
    seen="${seen}${t} "
    out+=("${t}")
  done
  printf '%s\n' "${out[@]}"
}

PKGS=( "php${PHP_VERSION}-cli" "php${PHP_VERSION}-common" "php${PHP_VERSION}-readline" )

if [ "${INSTALL_FPM}" = "true" ]; then
  PKGS+=( "php${PHP_VERSION}-fpm" )
fi

# Build a sanitized, deduped list of apt extensions for the requested PHP
# version. packages.sury.org/php/main only ships a subset of PECL extensions;
# the rest go through `pecl install` below.
SANITIZED_EXTS=()
while IFS= read -r ext; do
  [ -z "${ext}" ] && continue
  SANITIZED_EXTS+=("${ext}")
done < <(sanitize_extensions "${PHP_EXTENSIONS}")

for ext in "${SANITIZED_EXTS[@]}"; do
  PKGS+=( "php${PHP_VERSION}-${ext}" )
done

# PECL extensions to build from source. `xdebug` is a zend_extension; install
# via PECL when requested by either installXdebug=true or pecl='xdebug'.
PECL_LIST=()
for tok in ${PHP_PECL}; do
  tok_lc="$(echo "${tok}" | tr '[:upper:]' '[:lower:]')"
  case "${tok_lc}" in
    ""|*[!a-z0-9_-]*) continue ;;
  esac
  # Skip duplicates.
  found=0
  for existing in "${PECL_LIST[@]}"; do
    [ "${existing}" = "${tok_lc}" ] && { found=1; break; }
  done
  [ "${found}" -eq 0 ] && PECL_LIST+=("${tok_lc}")
done
if [ "${INSTALL_XDEBUG}" = "true" ]; then
  already=0
  for e in "${PECL_LIST[@]}"; do
    [ "${e}" = "xdebug" ] && { already=1; break; }
  done
  [ "${already}" -eq 0 ] && PECL_LIST+=("xdebug")
fi

# When PECL builds are needed, install php-dev + build toolchain.
if [ "${#PECL_LIST[@]}" -gt 0 ]; then
  PKGS+=( "php${PHP_VERSION}-dev" "php-pear" build-essential autoconf pkg-config libssl-dev )
fi

apt-get install -y --no-install-recommends "${PKGS[@]}"

# Build each PECL extension.
if [ "${#PECL_LIST[@]}" -gt 0 ]; then
  pecl channel-update pecl.php.net 2>/dev/null || true
  for ext in "${PECL_LIST[@]}"; do
    echo "php feature: building PECL extension '${ext}'"
    if pecl list "${ext}" 2>/dev/null | grep -q "${ext}"; then
      echo "  already installed, skipping"
      continue
    fi
    yes '' 2>/dev/null | pecl install --force "${ext}" || {
      echo "php feature: WARN — pecl install ${ext} failed; skipping" >&2
      continue
    }
    # Drop a conf.d entry pointing at the just-built .so.
    if [ "${ext}" = "xdebug" ]; then
      INI_LINE="zend_extension=xdebug.so"
    else
      INI_LINE="extension=${ext}.so"
    fi
    for sapi_dir in /etc/php/${PHP_VERSION}/cli/conf.d /etc/php/${PHP_VERSION}/fpm/conf.d; do
      [ -d "${sapi_dir}" ] || continue
      echo "${INI_LINE}" > "${sapi_dir}/30-${ext}.ini"
    done
  done
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

# --- make plain `php` resolve to the requested version ----------------------
if [ -x "/usr/bin/php${PHP_VERSION}" ]; then
  update-alternatives --set php "/usr/bin/php${PHP_VERSION}" >/dev/null 2>&1 \
    || update-alternatives --install /usr/bin/php php "/usr/bin/php${PHP_VERSION}" 100
fi

# --- FPM pool runs as the dev user ------------------------------------------
# Without this rewrite, the default pool runs as www-data and can't write
# files owned by the dev user during development.
if [ "${INSTALL_FPM}" = "true" ]; then
  POOL="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
  if [ -f "${POOL}" ] && [ "${USERNAME}" != "root" ]; then
    sed -i "s|^user = .*|user = ${USERNAME}|"      "${POOL}"
    sed -i "s|^group = .*|group = ${USER_GROUP}|"  "${POOL}"
    sed -i "s|^listen.owner = .*|listen.owner = ${USERNAME}|" "${POOL}"
    sed -i "s|^listen.group = .*|listen.group = ${USER_GROUP}|" "${POOL}"
  fi
fi

# --- Composer (official installer with hash verification) -------------------
if [ "${INSTALL_COMPOSER}" = "true" ]; then
  EXPECTED_HASH="$(curl -fsSL https://composer.github.io/installer.sig)"
  TMP_INSTALLER="$(mktemp)"
  curl -fsSL https://getcomposer.org/installer -o "${TMP_INSTALLER}"
  ACTUAL_HASH="$(php -r "echo hash_file('sha384','${TMP_INSTALLER}');")"
  if [ "${EXPECTED_HASH}" != "${ACTUAL_HASH}" ]; then
    echo "php feature: ERROR — composer installer hash mismatch" >&2
    echo "  expected: ${EXPECTED_HASH}" >&2
    echo "  actual:   ${ACTUAL_HASH}" >&2
    rm -f "${TMP_INSTALLER}"
    exit 1
  fi
  php "${TMP_INSTALLER}" --quiet --install-dir=/usr/local/bin --filename=composer
  rm -f "${TMP_INSTALLER}"
  chmod 0755 /usr/local/bin/composer

  # Shared COMPOSER_HOME so global packages survive UID remap and are available
  # to every shell. Mirrors the mise/cargo/opam approach used elsewhere here.
  COMPOSER_HOME="/usr/local/share/composer"
  install -d -m 0775 "${COMPOSER_HOME}"
  chown -R "${USERNAME}:${USER_GROUP}" "${COMPOSER_HOME}"
  chmod -R a+rwX "${COMPOSER_HOME}"
  find "${COMPOSER_HOME}" -type d -exec chmod g+s {} +
fi

# --- /etc/profile.d export for COMPOSER_HOME + global bin dir ---------------
cat > /etc/profile.d/devcontainer-php.sh <<EOF
export COMPOSER_HOME="/usr/local/share/composer"
export COMPOSER_ALLOW_SUPERUSER=1
case ":\${PATH}:" in
  *":/usr/local/share/composer/vendor/bin:"*) ;;
  *) export PATH="/usr/local/share/composer/vendor/bin:\${PATH}" ;;
esac
EOF
chmod 0644 /etc/profile.d/devcontainer-php.sh

# --- composer global packages -----------------------------------------------
run_as_user() {
  if [ "${USERNAME}" = "root" ]; then
    env COMPOSER_HOME=/usr/local/share/composer COMPOSER_ALLOW_SUPERUSER=1 "$@"
  else
    sudo -u "${USERNAME}" --preserve-env=COMPOSER_HOME,COMPOSER_ALLOW_SUPERUSER \
      env COMPOSER_HOME=/usr/local/share/composer COMPOSER_ALLOW_SUPERUSER=1 "$@"
  fi
}

if [ "${INSTALL_COMPOSER}" = "true" ] && [ -n "${COMPOSER_PACKAGES// }" ]; then
  # shellcheck disable=SC2086
  run_as_user /usr/local/bin/composer global require --no-interaction --no-progress ${COMPOSER_PACKAGES}
fi

# --- Symfony CLI (root install) ---------------------------------------------
if [ "${INSTALL_SYMFONY_CLI}" = "true" ]; then
  # Install to /usr/local/bin/symfony, no interactive prompts.
  curl -fsSL https://get.symfony.com/cli/installer -o /tmp/symfony-installer.sh
  SYMFONY_BIN_DIR="/usr/local/bin" bash /tmp/symfony-installer.sh --install-dir=/usr/local/bin
  rm -f /tmp/symfony-installer.sh
  if [ -x "/root/.symfony5/bin/symfony" ] && [ ! -x /usr/local/bin/symfony ]; then
    install -m 0755 /root/.symfony5/bin/symfony /usr/local/bin/symfony
  fi
fi

# --- Laravel installer (global composer package) ----------------------------
if [ "${INSTALL_LARAVEL_INSTALLER}" = "true" ]; then
  if [ "${INSTALL_COMPOSER}" != "true" ]; then
    echo "php feature: ERROR — installLaravelInstaller requires installComposer=true" >&2
    exit 1
  fi
  run_as_user /usr/local/bin/composer global require --no-interaction --no-progress laravel/installer
  if [ -x "/usr/local/share/composer/vendor/bin/laravel" ]; then
    ln -sf /usr/local/share/composer/vendor/bin/laravel /usr/local/bin/laravel
  fi
fi

# --- per-user shell activation ----------------------------------------------
ensure_line() {
  local file="$1" line="$2"
  touch "${file}"
  grep -qxF "${line}" "${file}" || echo "${line}" >> "${file}"
  chown "${USERNAME}:${USER_GROUP}" "${file}" 2>/dev/null || true
}

if [ "${USERNAME}" != "root" ]; then
  USER_HOME="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  ensure_line "${USER_HOME}/.bashrc" 'export COMPOSER_HOME="/usr/local/share/composer"'
  ensure_line "${USER_HOME}/.bashrc" 'export PATH="/usr/local/share/composer/vendor/bin:$PATH"'

  if [ -f "${USER_HOME}/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
    ensure_line "${USER_HOME}/.zshrc" 'export COMPOSER_HOME="/usr/local/share/composer"'
    ensure_line "${USER_HOME}/.zshrc" 'export PATH="/usr/local/share/composer/vendor/bin:$PATH"'
  fi
fi

# --- sanity -----------------------------------------------------------------
php -v 2>&1 | head -n1 || true
if [ "${INSTALL_COMPOSER}" = "true" ]; then
  composer --version 2>&1 | head -n1 || true
fi
echo "php feature: enabled extensions:"
php -m 2>&1 | grep -v '^\[' | head -n40 || true

echo "php feature: done"
