#!/usr/bin/env bash
# Feature: frankenphp
# Installs FrankenPHP as a single static binary from the official GitHub
# releases. FrankenPHP embeds its own PHP runtime; it is independent of the
# `php` feature but composes nicely alongside it.
set -euo pipefail

FRANKENPHP_VERSION="${VERSION:-latest}"

if [ "$(id -u)" -ne 0 ]; then
  echo "frankenphp feature: must run as root" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl jq libcap2-bin
apt-get clean
rm -rf /var/lib/apt/lists/*

# Resolve `latest` to a concrete tag via the GitHub API (no auth needed for
# public release metadata; fall back to `gh` if it's available).
if [ "${FRANKENPHP_VERSION}" = "latest" ]; then
  if command -v gh >/dev/null 2>&1; then
    FRANKENPHP_VERSION="$(gh release view --repo php/frankenphp --json tagName -q .tagName)"
  else
    FRANKENPHP_VERSION="$(curl -fsSL https://api.github.com/repos/php/frankenphp/releases/latest | jq -r .tag_name)"
  fi
  if [ -z "${FRANKENPHP_VERSION}" ] || [ "${FRANKENPHP_VERSION}" = "null" ]; then
    echo "frankenphp feature: ERROR — could not resolve 'latest' tag" >&2
    exit 1
  fi
fi

echo "frankenphp feature: installing ${FRANKENPHP_VERSION}"

# Map dpkg arch → FrankenPHP release asset.
case "$(dpkg --print-architecture)" in
  amd64) ASSET="frankenphp-linux-x86_64" ;;
  arm64) ASSET="frankenphp-linux-aarch64" ;;
  *)
    echo "frankenphp feature: ERROR — unsupported architecture $(dpkg --print-architecture)" >&2
    exit 1
    ;;
esac

URL="https://github.com/php/frankenphp/releases/download/${FRANKENPHP_VERSION}/${ASSET}"
curl -fsSL "${URL}" -o /usr/local/bin/frankenphp
chmod 0755 /usr/local/bin/frankenphp

# Allow binding low ports (80, 443) without root.
setcap cap_net_bind_service=+ep /usr/local/bin/frankenphp || true

frankenphp version 2>&1 | head -n1 || true
echo "frankenphp feature: done"
