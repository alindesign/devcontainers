#!/usr/bin/env bash
# Feature: mailpit
# Installs Mailpit as a single binary from the official GitHub releases and
# registers a services-dispatcher script that starts it on container boot.
set -euo pipefail

MAILPIT_VERSION="${VERSION:-latest}"
SMTP_PORT="${SMTPPORT:-1025}"
UI_PORT="${UIPORT:-8025}"

if [ "$(id -u)" -ne 0 ]; then
  echo "mailpit feature: must run as root" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl jq tar
apt-get clean
rm -rf /var/lib/apt/lists/*

if [ "${MAILPIT_VERSION}" = "latest" ]; then
  if command -v gh >/dev/null 2>&1; then
    MAILPIT_VERSION="$(gh release view --repo axllent/mailpit --json tagName -q .tagName)"
  else
    MAILPIT_VERSION="$(curl -fsSL https://api.github.com/repos/axllent/mailpit/releases/latest | jq -r .tag_name)"
  fi
  if [ -z "${MAILPIT_VERSION}" ] || [ "${MAILPIT_VERSION}" = "null" ]; then
    echo "mailpit feature: ERROR — could not resolve 'latest' tag" >&2
    exit 1
  fi
fi

echo "mailpit feature: installing ${MAILPIT_VERSION} (smtp=${SMTP_PORT} ui=${UI_PORT})"

case "$(dpkg --print-architecture)" in
  amd64) ASSET="mailpit-linux-amd64.tar.gz" ;;
  arm64) ASSET="mailpit-linux-arm64.tar.gz" ;;
  *)
    echo "mailpit feature: ERROR — unsupported architecture $(dpkg --print-architecture)" >&2
    exit 1
    ;;
esac

URL="https://github.com/axllent/mailpit/releases/download/${MAILPIT_VERSION}/${ASSET}"
TMP="$(mktemp -d)"
curl -fsSL "${URL}" -o "${TMP}/mailpit.tar.gz"
tar -xzf "${TMP}/mailpit.tar.gz" -C "${TMP}"
install -m 0755 "${TMP}/mailpit" /usr/local/bin/mailpit
rm -rf "${TMP}"

# --- services dispatcher script ---------------------------------------------
install -d -m 0755 /etc/devcontainer-services.d /var/lib/mailpit /var/log/mailpit

cat > /etc/devcontainer-services.d/40-mailpit.conf <<EOF
SMTP_PORT=$(printf '%q' "${SMTP_PORT}")
UI_PORT=$(printf '%q' "${UI_PORT}")
EOF
chmod 0644 /etc/devcontainer-services.d/40-mailpit.conf

cat > /etc/devcontainer-services.d/40-mailpit.sh <<'EOF'
#!/usr/bin/env bash
# devcontainer service: mailpit
set -e

# shellcheck disable=SC1091
. /etc/devcontainer-services.d/40-mailpit.conf

# Skip if already up.
if curl -fsS "http://127.0.0.1:${UI_PORT}/api/v1/info" >/dev/null 2>&1; then
  exit 0
fi

install -d -m 0755 /var/lib/mailpit /var/log/mailpit

nohup /usr/local/bin/mailpit \
  --smtp "0.0.0.0:${SMTP_PORT}" \
  --listen "0.0.0.0:${UI_PORT}" \
  --db-file /var/lib/mailpit/mailpit.db \
  > /var/log/mailpit/init.log 2>&1 &

for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${UI_PORT}/api/v1/info" >/dev/null 2>&1; then
    exit 0
  fi
  sleep 0.2
done

echo "mailpit service: failed to become ready (see /var/log/mailpit/init.log)" >&2
exit 1
EOF
chmod 0755 /etc/devcontainer-services.d/40-mailpit.sh

# --- entrypoint wrapper -----------------------------------------------------
cat > /usr/local/share/mailpit-init.sh <<'EOF'
#!/usr/bin/env bash
# devcontainer entrypoint: shared services dispatcher.
set -e

SENTINEL=/run/devcontainer-services.dispatched
if [ ! -e "${SENTINEL}" ]; then
  if [ -d /etc/devcontainer-services.d ]; then
    run-parts --regex '^[0-9]+-.*\.sh$' /etc/devcontainer-services.d/ || true
  fi
  touch "${SENTINEL}" 2>/dev/null || true
fi

if [ $# -gt 0 ]; then
  exec "$@"
else
  exec sleep infinity
fi
EOF
chmod 0755 /usr/local/share/mailpit-init.sh

# --- profile.d export -------------------------------------------------------
cat > /etc/profile.d/devcontainer-mailpit.sh <<EOF
: "\${MAIL_HOST:=127.0.0.1}"
: "\${MAIL_PORT:=${SMTP_PORT}}"
: "\${MAIL_MAILER:=smtp}"
export MAIL_HOST MAIL_PORT MAIL_MAILER
EOF
chmod 0644 /etc/profile.d/devcontainer-mailpit.sh

mailpit version 2>&1 | head -n1 || true
echo "mailpit feature: done"
