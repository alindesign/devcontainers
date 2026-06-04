# mysql

In-container MySQL Community Server from Oracle's official APT repository. Data persists in a named volume (`mysql-data-${devcontainerId}`); `mysqld` starts on container boot via the shared services dispatcher (`/etc/devcontainer-services.d/`).

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `8.4` | `8.4` (LTS, supported to 2032), `8.0`, or `9.x` (innovation). |
| `rootPassword` | string | `""` | Empty = unix_socket auth for root (recommended for dev). Setting it switches root to password auth. |
| `createDatabase` | string | `""` | Initial database created on first boot. |
| `createUser` | string | `""` | Initial user (granted ALL on `createDatabase`). |
| `createPassword` | string | `""` | Password for `createUser`. |
| `port` | string | `3306` | TCP port `mysqld` listens on (bind 127.0.0.1). |

## Use

```jsonc
{
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
  "features": {
    "ghcr.io/alindesign/features/php:1": {},
    "ghcr.io/alindesign/features/mysql:1": {
      "createDatabase": "app",
      "createUser": "app",
      "createPassword": "app"
    }
  }
}
```

After the container starts, connect with:

```bash
mysql -h 127.0.0.1 -u app -papp app
```

## Notes

- `mysqld` binds `127.0.0.1` — it's reachable from within the container but not from the host (use `forwardPorts` if you want host access).
- Setting `rootPassword` switches root to password auth (`caching_sha2_password`). Otherwise root is reachable only via the socket as the `root` OS user (run `sudo mysql`).
- The data volume survives `Rebuild Container`; it does NOT survive removing the named volume manually.
- Composes with [`postgres`](../postgres), [`redis`](../redis), [`mailpit`](../mailpit) — all use the same `/etc/devcontainer-services.d/` dispatcher so multiple servers start in sequence on boot.

## When to use docker-compose instead

Single-container MySQL is convenient for solo dev. Use docker-compose with a dedicated `db` service container when:
- Multiple developers share the same project and need identical data
- You want prod-parity (separate db host, separate networking)
- You need multiple MySQL versions side-by-side for the same project
- Memory pressure matters (mysqld + php + node + editor in one container is ~1.5 GB resident)
