# mailpit

[Mailpit](https://mailpit.axllent.org/) — local SMTP catcher with web UI. Captures every outgoing email so you can inspect it without ever sending a real message. Near-universal in PHP dev workflows (Symfony Mailer, Laravel Mail, PHPMailer, etc.).

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | GitHub release tag or `latest`. |
| `smtpPort` | string | `1025` | SMTP listener. |
| `uiPort` | string | `8025` | Web UI listener (HTTP). |

## Use

```jsonc
{
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
  "features": {
    "ghcr.io/alindesign/features/php:1": {},
    "ghcr.io/alindesign/features/mailpit:1": {}
  },
  "forwardPorts": [8025]
}
```

Once the container is up, open the forwarded port `8025` in your browser to inspect captured mail.

Container env defaults so most PHP frameworks pick it up automatically:

- `MAIL_HOST=127.0.0.1`
- `MAIL_PORT=1025`
- `MAIL_MAILER=smtp`

(Laravel and Symfony both honour these via `.env` if you don't override.)

## Notes

- Mailpit listens on `0.0.0.0` (inside the container) so the SMTP port is reachable from any process in the same container.
- Data persists at `/var/lib/mailpit/mailpit.db` for the lifetime of the container (not via a named volume — captured mail is ephemeral by intent).
- Composes with [`mysql`](../mysql), [`postgres`](../postgres), [`redis`](../redis) through the shared `/etc/devcontainer-services.d/` dispatcher.
