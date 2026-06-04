# Symfony (alindesign) — devcontainer template

Full Symfony dev stack in one container:

- `ghcr.io/alindesign/devcontainer-base:latest` — Ubuntu base with `dotfiles` + `mise` pre-installed
- [`php`](../../../src/php) — PHP via Sury + Composer + Symfony CLI
- [`node`](../../../src/node) — Node LTS via mise (Webpack Encore / AssetMapper)
- [`postgres`](../../../src/postgres) — PostgreSQL 18, pre-seeded database/role
- [`redis`](../../../src/redis) — Redis 8 server
- [`frankenphp`](../../../src/frankenphp) — modern app-server
- [`mailpit`](../../../src/mailpit) — local SMTP catcher (UI on port 8025)
- [`db-tooling`](../../../src/db-tooling) — CLI clients

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/symfony:latest \
  --template-args '{"appDatabase":"myapp","appUser":"myapp","appPassword":"secret"}' \
  --workspace-folder .
```

## Inside the container

```bash
# Scaffold a new app (if your workspace is empty)
symfony new app --webapp
cd app

# .env.local example matching this template:
# DATABASE_URL="postgresql://symfony:symfony@127.0.0.1:5432/symfony?serverVersion=18&charset=utf8"
# REDIS_URL="redis://127.0.0.1:6379"
# MAILER_DSN="smtp://127.0.0.1:1025"

symfony console doctrine:migrations:migrate
symfony serve                # plain dev server
frankenphp run               # OR FrankenPHP
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `phpVersion` | `8.4` | PHP version. |
| `nodeVersion` | `lts` | Node version. |
| `appDatabase` | `symfony` | PostgreSQL database. |
| `appUser` | `symfony` | PostgreSQL role (LOGIN + CREATEDB). |
| `appPassword` | `symfony` | PostgreSQL password. |
| `gitUserName` | `""` | git user.name (optional). |
| `gitUserEmail` | `""` | git user.email (optional). |
