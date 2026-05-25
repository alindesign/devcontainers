#!/usr/bin/env bash
# Feature: gcloud
# Installs Google Cloud CLI via the official Google apt repository.
set -euo pipefail

INSTALL_COMPONENTS="${INSTALLCOMPONENTS:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "gcloud feature: must run as root" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg apt-transport-https python3
apt-get clean
rm -rf /var/lib/apt/lists/*

# --- add Google Cloud apt repo ---------------------------------------------
install -d -m 0755 /usr/share/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | gpg --batch --yes --dearmor -o /usr/share/keyrings/cloud.google.gpg

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  > /etc/apt/sources.list.d/google-cloud-sdk.list

apt-get update -y
apt-get install -y --no-install-recommends google-cloud-cli

# --- optional components ----------------------------------------------------
if [ -n "${INSTALL_COMPONENTS}" ]; then
  # Components shipped as apt packages: google-cloud-cli-<name>
  # shellcheck disable=SC2086
  pkgs=""
  for c in ${INSTALL_COMPONENTS}; do
    pkgs="${pkgs} google-cloud-cli-${c}"
  done
  # shellcheck disable=SC2086
  apt-get install -y --no-install-recommends ${pkgs} || {
    echo "gcloud feature: some components failed to install via apt; falling back to gcloud components install"
    # shellcheck disable=SC2086
    gcloud components install --quiet ${INSTALL_COMPONENTS} || true
  }
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

gcloud --version | head -n1
echo "gcloud feature: done"
