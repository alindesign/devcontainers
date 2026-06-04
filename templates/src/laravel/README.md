# Laravel (alindesign) — devcontainer template

Full Laravel dev stack in one container:

- `ghcr.io/alindesign/devcontainer-base:latest` — Ubuntu base with `dotfiles` + `mise` pre-installed
- [`php`](../../../src/php) — PHP via Sury + Composer + Laravel installer
- [`node`](../../../src/node) — Node LTS via mise (for Vite)
- [`mysql`](../../../src/mysql) — MySQL 8.4 LTS server, pre-seeded database/user
- [`redis`](../../../src/redis) — Redis 8 server
- [`frankenphp`](../../../src/frankenphp) — modern app-server alternative to `php artisan serve`
- [`mailpit`](../../../src/mailpit) — local SMTP catcher (UI on port 8025)
- [`db-tooling`](../../../src/db-tooling) — CLI clients

All servers start automatically on container boot via the shared services dispatcher.

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/laravel:latest \
  --template-args '{"appDatabase":"myapp","appUser":"myapp","appPassword":"secret"}' \
  --workspace-folder .
```

## Inside the container

```bash
# Scaffold a new app (if your workspace is empty)
laravel new app

# .env defaults that match this template:
# DB_CONNECTION=mysql DB_HOST=127.0.0.1 DB_PORT=3306 DB_DATABASE=laravel DB_USERNAME=laravel DB_PASSWORD=laravel
# REDIS_HOST=127.0.0.1 REDIS_PORT=6379
# MAIL_MAILER=smtp MAIL_HOST=127.0.0.1 MAIL_PORT=1025

cd app
php artisan migrate
php artisan serve            # plain dev server on :8000
frankenphp run               # OR FrankenPHP (HTTP/3, worker mode)
```

Mail goes to Mailpit at http://localhost:8025.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `phpVersion` | `8.4` | PHP version. |
| `nodeVersion` | `lts` | Node version (Vite). |
| `appDatabase` | `laravel` | MySQL database created on first boot. |
| `appUser` | `laravel` | MySQL user (granted ALL on appDatabase). |
| `appPassword` | `laravel` | MySQL password for appUser. |
| `gitUserName` | `""` | git user.name (optional). |
| `gitUserEmail` | `""` | git user.email (optional). |

See each feature's README for advanced options.
