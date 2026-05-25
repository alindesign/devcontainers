# node

Node.js via `nvm` (system-wide install at `/usr/local/share/nvm`) with a configurable package manager. `pnpm` is the default; `npm` and `yarn` are supported. Package managers other than `npm` are activated through `corepack`.

## Why nvm + corepack

- `nvm` lets the project bump or pin Node versions later without rebuilding the image.
- `corepack` is the [official Node.js way](https://nodejs.org/api/corepack.html) to manage `pnpm`/`yarn` versions per project — pin via `packageManager` in `package.json` and corepack honors it.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `lts` | `lts`, `latest`, major (e.g. `22`), or full (`22.11.0`) |
| `packageManager` | string | `pnpm` | One of `pnpm`, `npm`, `yarn`, `none` |
| `packageManagerVersion` | string | `latest` | Version pinned via corepack for `pnpm`/`yarn`. Ignored for `npm`/`none`. |

`none` skips activating any default — useful if every project pins its own via `package.json#packageManager` and you want corepack to take over from there.

## Use

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/alindesign/features/node:1": {
      "version": "lts",
      "packageManager": "pnpm"
    }
  }
}
```

Switch package manager:

```jsonc
"ghcr.io/alindesign/features/node:1": { "packageManager": "yarn", "packageManagerVersion": "4.5.0" }
```

```jsonc
"ghcr.io/alindesign/features/node:1": { "packageManager": "npm" }
```

## Notes

- Installs `node`, `npm`, `npx`, plus the activated package manager as symlinks under `/usr/local/bin` so non-login shells (`RUN` steps, scripts, CI) see them without sourcing `nvm.sh`.
- Login/interactive shells (bash, zsh) get `nvm` itself, so `nvm install 20`, `nvm use 22` etc. work inside the container.
- `NVM_DIR` is group-writable so the remote user can install additional Node versions.
- Composes cleanly with the `dotfiles` feature — `dotfiles` already sources `NVM_DIR` in its `.zshrc`.
