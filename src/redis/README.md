# redis

In-container Redis server from the [official Redis APT repo](https://packages.redis.io/), or its BSD-3 fork [Valkey](https://valkey.io/) via the `variant` option. Data persists in a named volume (`redis-data-${devcontainerId}`); the daemon starts on container boot via the shared services dispatcher.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `variant` | string | `redis` | `redis` (AGPLv3, upstream) or `valkey` (BSD-3 fork, drop-in compatible). |
| `password` | string | `""` | Optional `requirepass`. Empty disables auth (recommended for dev). |
| `port` | string | `6379` | TCP port (bind 127.0.0.1). |

## Use

```jsonc
{
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
  "features": {
    "ghcr.io/alindesign/features/php:1": {},
    "ghcr.io/alindesign/features/redis:1": {}
  }
}
```

After the container starts:

```bash
redis-cli ping       # → PONG
```

## Notes

- For `variant: valkey`, the feature installs `valkey-server`/`valkey-cli` from apt (Ubuntu 24.04+ ships this) and creates `redis-server`/`redis-cli` symlinks in `/usr/local/bin/` for compatibility with tools that hard-code those names.
- Persistence: `appendonly yes`, `appendfsync everysec` — good dev defaults; survives container restart but **not** named-volume deletion.
- Composes with [`mysql`](../mysql), [`postgres`](../postgres), [`mailpit`](../mailpit) through the shared `/etc/devcontainer-services.d/` dispatcher.

## When to use docker-compose instead

Same caveats as [`mysql`](../mysql) — for multi-developer shared state, prod-parity, or running multiple Redis versions side-by-side, prefer a dedicated `cache` service container with docker-compose.
