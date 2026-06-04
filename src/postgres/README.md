# postgres

In-container PostgreSQL from the [PGDG](https://www.postgresql.org/download/linux/ubuntu/) APT repository. Data persists in a named volume (`postgres-data-${devcontainerId}`); the server starts on container boot via the shared services dispatcher (`/etc/devcontainer-services.d/`).

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `18` | PostgreSQL major version. PGDG packages 15–18 in parallel. |
| `rootPassword` | string | `postgres` | Password for the `postgres` superuser. Used for password auth from TCP. |
| `createDatabase` | string | `""` | Initial database created on first boot. |
| `createUser` | string | `""` | Initial role (LOGIN + CREATEDB). |
| `createPassword` | string | `""` | Password for `createUser`. |
| `port` | string | `5432` | TCP port (bind 127.0.0.1). |

## Use

```jsonc
{
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
  "features": {
    "ghcr.io/alindesign/features/php:1": {},
    "ghcr.io/alindesign/features/postgres:1": {
      "createDatabase": "app",
      "createUser": "app",
      "createPassword": "app"
    }
  }
}
```

After the container starts:

```bash
psql -h 127.0.0.1 -U app -d app   # prompts for password
```

Or from the OS `root` (no password, via local trust):

```bash
sudo -u postgres psql
```

## Notes

- The cluster is initialised with `--auth-local=trust` and `--auth-host=scram-sha-256`. Local socket connections from `postgres` (or root via sudo) skip authentication; TCP requires a password.
- The data volume mount targets `/var/lib/postgresql` (everything PGDG writes), so all PG versions you install share one volume.
- Ownership is re-applied on every boot (`chown -R postgres:postgres /var/lib/postgresql`) — guards against uid drift across apt upgrades.
- Composes with [`mysql`](../mysql), [`redis`](../redis), [`mailpit`](../mailpit) through the shared dispatcher.

## When to use docker-compose instead

The same caveats as [`mysql`](../mysql) apply — multi-developer shared state, prod-parity, multiple PG versions side-by-side, or RAM pressure tip the scales toward docker-compose with a dedicated `db` service container.
