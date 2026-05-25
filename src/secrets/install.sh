#!/usr/bin/env bash
# Feature: secrets
# sops + age + pass for dev/IaC secret management. Versions pinned-by-default
# to avoid GitHub API rate limits when 'latest' is requested in CI.
set -euo pipefail

SOPS_VERSION="${SOPSVERSION:-latest}"
AGE_VERSION="${AGEVERSION:-latest}"
INSTALL_PASS="${INSTALLPASS:-true}"

if [ "$(id -u)" -ne 0 ]; then
  echo "secrets feature: must run as root" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl tar

PASS_PKGS=()
if [ "${INSTALL_PASS}" = "true" ]; then
  PASS_PKGS+=(pass gnupg2)
fi
if [ "${#PASS_PKGS[@]}" -gt 0 ]; then
  apt-get install -y --no-install-recommends "${PASS_PKGS[@]}"
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

arch="$(uname -m)"
case "${arch}" in
  x86_64|amd64) GO_ARCH=amd64 ;;
  aarch64|arm64) GO_ARCH=arm64 ;;
  *) echo "secrets feature: unsupported arch ${arch}" >&2; exit 1 ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

# --- sops ------------------------------------------------------------------
SOPS_KNOWN_GOOD="v3.9.1"
case "${SOPS_VERSION}" in
  latest) sv="${SOPS_KNOWN_GOOD}" ;;
  v*) sv="${SOPS_VERSION}" ;;
  *)  sv="v${SOPS_VERSION}" ;;
esac
curl -fsSL -o /usr/local/bin/sops "https://github.com/getsops/sops/releases/download/${sv}/sops-${sv}.linux.${GO_ARCH}"
chmod 0755 /usr/local/bin/sops
sops --version | head -n1

# --- age + age-keygen ------------------------------------------------------
AGE_KNOWN_GOOD="v1.2.0"
case "${AGE_VERSION}" in
  latest) av="${AGE_KNOWN_GOOD}" ;;
  v*) av="${AGE_VERSION}" ;;
  *)  av="v${AGE_VERSION}" ;;
esac
curl -fsSL "https://github.com/FiloSottile/age/releases/download/${av}/age-${av}-linux-${GO_ARCH}.tar.gz" \
  | tar -xz -C "${TMP}"
install -m 0755 "${TMP}/age/age" /usr/local/bin/age
install -m 0755 "${TMP}/age/age-keygen" /usr/local/bin/age-keygen
age --version | head -n1
age-keygen --version 2>/dev/null | head -n1 || true

echo "secrets feature: done"
