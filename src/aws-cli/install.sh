#!/usr/bin/env bash
# Feature: aws-cli
# Installs AWS CLI v2 from the official zipped installer.
set -euo pipefail

AWS_VERSION="${VERSION:-latest}"

if [ "$(id -u)" -ne 0 ]; then
  echo "aws-cli feature: must run as root" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl unzip groff less
apt-get clean
rm -rf /var/lib/apt/lists/*

arch="$(uname -m)"
case "${arch}" in
  x86_64|amd64)  AWS_ARCH="x86_64" ;;
  aarch64|arm64) AWS_ARCH="aarch64" ;;
  *) echo "aws-cli feature: unsupported arch ${arch}" >&2; exit 1 ;;
esac

if [ "${AWS_VERSION}" = "latest" ]; then
  URL="https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip"
else
  URL="https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}-${AWS_VERSION}.zip"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

curl -fsSL "${URL}" -o "${TMP}/awscliv2.zip"
unzip -q "${TMP}/awscliv2.zip" -d "${TMP}"

# Idempotent install: --update if AWS CLI already exists.
if [ -d /usr/local/aws-cli ]; then
  "${TMP}/aws/install" --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
else
  "${TMP}/aws/install" --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli
fi

aws --version
echo "aws-cli feature: done"
