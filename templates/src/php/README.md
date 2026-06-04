# PHP (alindesign) — devcontainer template

Bootstraps a `.devcontainer/devcontainer.json` for a PHP project with:

- `ghcr.io/alindesign/devcontainer-base:latest` — Ubuntu base with `dotfiles` + `mise` pre-installed
- `ghcr.io/alindesign/features/php:1` — PHP via Sury + Composer + configurable extensions
- `ghcr.io/alindesign/features/db-tooling:1` — CLI clients (psql, mysql, redis-cli, mongosh)

Add the [`mysql`](../../../src/mysql), [`postgres`](../../../src/postgres), [`redis`](../../../src/redis), [`frankenphp`](../../../src/frankenphp), or [`mailpit`](../../../src/mailpit) features to your generated `devcontainer.json` as needed — or start from the [`laravel`](../laravel) / [`symfony`](../symfony) templates which wire them up.

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/php:latest \
  --template-args '{"phpVersion":"8.4"}' \
  --workspace-folder .
```

Or, from VS Code: `Dev Containers: New Dev Container...` → `PHP (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `phpVersion` | `8.4` | PHP `MAJOR.MINOR`. |
| `phpExtensions` | (curated set) | Space-separated extension list. |
| `installXdebug` | `false` | Install Xdebug. |
| `gitUserName` | `""` | git user.name (optional). |
| `gitUserEmail` | `""` | git user.email (optional). |
