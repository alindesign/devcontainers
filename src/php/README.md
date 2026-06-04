# php

PHP via the [Sury repository](https://deb.sury.org/) (`packages.sury.org/php/`), with Composer, a configurable extension set, and opt-in Xdebug / FPM / Symfony CLI / Laravel installer.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `8.4` | PHP `MAJOR.MINOR`. Sury publishes 8.1–8.5 (and newer) co-installable. |
| `extensions` | string | `mbstring intl xml zip gd curl mysql pgsql redis opcache sodium bcmath pcntl gmp` | Space-separated. Each becomes `php<version>-<ext>` (or `php-<ext>` for `imagick`, `memcached`, `mongodb`, `amqp` which Sury ships un-versioned). |
| `installComposer` | boolean | `true` | Composer 2 via the official installer with SHA-384 verification. |
| `installXdebug` | boolean | `false` | Adds `php<version>-xdebug`. |
| `installFpm` | boolean | `false` | Adds `php<version>-fpm` and rewrites the default pool to run as the remote user. |
| `installSymfonyCli` | boolean | `false` | Installs the Symfony CLI to `/usr/local/bin/symfony`. |
| `installLaravelInstaller` | boolean | `false` | `composer global require laravel/installer`. Requires `installComposer: true`. |
| `composerPackages` | string | `""` | Space-separated extra global Composer packages (e.g. `phpstan/phpstan friendsofphp/php-cs-fixer`). |

## Use

```jsonc
{
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
  "features": {
    "ghcr.io/alindesign/features/php:1": {
      "version": "8.4",
      "installXdebug": true,
      "installSymfonyCli": true,
      "composerPackages": "phpstan/phpstan friendsofphp/php-cs-fixer"
    }
  }
}
```

## Notes

- `update-alternatives` is wired so plain `php` resolves to the requested version even when multiple PHP versions are installed.
- `COMPOSER_HOME=/usr/local/share/composer` is shared and world-writable so global packages survive UID remap and are visible to every shell. `vendor/bin` is placed on `PATH` via `/etc/profile.d/devcontainer-php.sh`.
- `pecl` extensions absent from Sury (e.g. `swoole`, `openswoole`) are out of scope here — install them per-project via `pecl install`.
- For a single-binary modern app server, pair this with [`frankenphp`](../frankenphp).
- For local SMTP catching, pair with [`mailpit`](../mailpit).
