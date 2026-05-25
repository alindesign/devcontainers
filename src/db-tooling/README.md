# db-tooling

CLI **clients** for the common databases. No servers are installed — this feature is for connecting to external/managed databases or to docker-compose services.

| Tool | Source | Skip flag |
| --- | --- | --- |
| `psql` (PostgreSQL) | apt: `postgresql-client` | `skipPostgres` |
| `mysql` (MySQL/MariaDB) | apt: `default-mysql-client` | `skipMysql` |
| `redis-cli` (Redis) | apt: `redis-tools` | `skipRedis` |
| `mongosh` (MongoDB) | MongoDB official apt repo | `skipMongosh` |

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `skipPostgres` | boolean | `false` | Skip postgresql-client. |
| `skipMysql` | boolean | `false` | Skip default-mysql-client. |
| `skipRedis` | boolean | `false` | Skip redis-tools. |
| `skipMongosh` | boolean | `false` | Skip mongosh. |

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/db-tooling:1": {
      "skipMongosh": true
    }
  }
}
```
