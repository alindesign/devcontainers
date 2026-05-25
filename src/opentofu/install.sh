#!/usr/bin/env bash
# Feature: opentofu
# Installs OpenTofu (open-source Terraform fork) from the official release.
set -euo pipefail

TOFU_VERSION="${VERSION:-latest}"
INSTALL_TFLINT="${INSTALLTFLINT:-true}"

if [ "$(id -u)" -ne 0 ]; then
  echo "opentofu feature: must run as root" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl unzip jq
apt-get clean
rm -rf /var/lib/apt/lists/*

arch="$(uname -m)"
case "${arch}" in
  x86_64|amd64) GO_ARCH=amd64 ;;
  aarch64|arm64) GO_ARCH=arm64 ;;
  *) echo "opentofu feature: unsupported arch ${arch}" >&2; exit 1 ;;
esac

resolve_tofu_version() {
  if [ "${TOFU_VERSION}" = "latest" ]; then
    # opentofu.org maintains a /api/version endpoint, but it's flaky; fall
    # back to a pinned-known-good when the API misbehaves.
    v="$(curl -fsSL https://get.opentofu.org/tofu/api.json 2>/dev/null | jq -r '.["current-version"] // empty' || true)"
    if [ -z "${v}" ]; then v="1.8.4"; fi
    echo "${v}"
  else
    echo "${TOFU_VERSION#v}"
  fi
}
TFV="$(resolve_tofu_version)"

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

URL="https://github.com/opentofu/opentofu/releases/download/v${TFV}/tofu_${TFV}_linux_${GO_ARCH}.zip"
curl -fsSL "${URL}" -o "${TMP}/tofu.zip"
unzip -q "${TMP}/tofu.zip" -d "${TMP}"
install -m 0755 "${TMP}/tofu" /usr/local/bin/tofu
# Convenience alias so muscle memory works.
ln -sf /usr/local/bin/tofu /usr/local/bin/terraform
tofu version | head -n1
echo "opentofu feature: tofu ${TFV} installed (terraform alias at /usr/local/bin/terraform)"

if [ "${INSTALL_TFLINT}" = "true" ]; then
  TFLINT_VERSION="v0.55.1"
  curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_${GO_ARCH}.zip" -o "${TMP}/tflint.zip"
  unzip -q -o "${TMP}/tflint.zip" -d "${TMP}"
  install -m 0755 "${TMP}/tflint" /usr/local/bin/tflint
  tflint --version | head -n1
fi

echo "opentofu feature: done"
