#!/usr/bin/env bash
# Feature: kubectl
# Installs kubectl + optionally helm, k9s, kubectx/kubens via direct binary
# downloads (versioned URLs, no GitHub API rate-limit dependency).
set -euo pipefail

KUBECTL_VERSION="${KUBECTLVERSION:-latest}"
HELM_VERSION="${HELMVERSION:-latest}"
INSTALL_HELM="${INSTALLHELM:-true}"
INSTALL_K9S="${INSTALLK9S:-true}"
INSTALL_KUBECTX="${INSTALLKUBECTX:-true}"

if [ "$(id -u)" -ne 0 ]; then
  echo "kubectl feature: must run as root" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl tar gzip jq
apt-get clean
rm -rf /var/lib/apt/lists/*

arch="$(uname -m)"
case "${arch}" in
  x86_64|amd64) GO_ARCH=amd64 ;;
  aarch64|arm64) GO_ARCH=arm64 ;;
  *) echo "kubectl feature: unsupported arch ${arch}" >&2; exit 1 ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

# --- kubectl ---------------------------------------------------------------
resolve_kubectl_version() {
  if [ "${KUBECTL_VERSION}" = "latest" ]; then
    curl -fsSL https://dl.k8s.io/release/stable.txt
  else
    case "${KUBECTL_VERSION}" in
      v*) echo "${KUBECTL_VERSION}" ;;
      *)  echo "v${KUBECTL_VERSION}" ;;
    esac
  fi
}
KCT_VER="$(resolve_kubectl_version)"
curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/${KCT_VER}/bin/linux/${GO_ARCH}/kubectl"
chmod 0755 /usr/local/bin/kubectl
kubectl version --client=true 2>/dev/null | head -n1 || true
echo "kubectl feature: kubectl ${KCT_VER} installed"

# --- helm ------------------------------------------------------------------
if [ "${INSTALL_HELM}" = "true" ]; then
  if [ "${HELM_VERSION}" = "latest" ]; then
    # Helm publishes get-helm-3 — fetch stable without GH API rate limit.
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
      | env USE_SUDO=false HELM_INSTALL_DIR=/usr/local/bin bash
  else
    case "${HELM_VERSION}" in
      v*) hv="${HELM_VERSION}" ;;
      *)  hv="v${HELM_VERSION}" ;;
    esac
    curl -fsSL "https://get.helm.sh/helm-${hv}-linux-${GO_ARCH}.tar.gz" | tar -xz -C "${TMP}"
    install -m 0755 "${TMP}/linux-${GO_ARCH}/helm" /usr/local/bin/helm
  fi
  helm version --short 2>/dev/null || true
fi

# --- k9s -------------------------------------------------------------------
if [ "${INSTALL_K9S}" = "true" ]; then
  # Pinned version to avoid GitHub API rate limits. Bump as needed.
  K9S_VERSION="v0.32.6"
  curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${GO_ARCH}.tar.gz" \
    | tar -xz -C "${TMP}" k9s
  install -m 0755 "${TMP}/k9s" /usr/local/bin/k9s
  k9s version 2>/dev/null | head -n1 || true
fi

# --- kubectx + kubens ------------------------------------------------------
if [ "${INSTALL_KUBECTX}" = "true" ]; then
  KUBECTX_VERSION="v0.9.5"
  base="https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}"
  for tool in kubectx kubens; do
    curl -fsSL "${base}/${tool}_${KUBECTX_VERSION}_linux_${GO_ARCH}.tar.gz" \
      | tar -xz -C "${TMP}" "${tool}"
    install -m 0755 "${TMP}/${tool}" "/usr/local/bin/${tool}"
  done
fi

echo "kubectl feature: done"
