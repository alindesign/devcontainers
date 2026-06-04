# frankenphp

[FrankenPHP](https://frankenphp.dev/) as a single static binary at `/usr/local/bin/frankenphp`. Caddy + embedded PHP, worker mode, HTTP/3 — the modern app-server runtime for PHP projects.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | GitHub release tag (e.g. `v1.11.3`) or `latest`. |

## Use

```jsonc
{
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
  "features": {
    "ghcr.io/alindesign/features/php:1": {},
    "ghcr.io/alindesign/features/frankenphp:1": {}
  }
}
```

Then in your project:

```bash
# Serve the current directory like nginx + php-fpm
frankenphp php-server -r .

# Worker mode (one bootstrapped process serves N requests)
frankenphp run --config Caddyfile
```

## Notes

- FrankenPHP **embeds its own PHP**. It does not use the `php` binary installed by the [`php`](../php) feature. If you run `php artisan serve` from the CLI and `frankenphp run` from another shell, they're two independent PHP versions sharing the same `.env`.
- `cap_net_bind_service` is set on the binary so it can listen on ports 80/443 without root.
- No entrypoint — you invoke `frankenphp` yourself (or wire it into the shared services dispatcher manually).
