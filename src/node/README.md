# node

Node.js via [mise](https://mise.jdx.dev), with a configurable package manager. `pnpm` is the default; `npm` and `yarn` are supported. Package managers other than `npm` are activated through `corepack`.

## Why mise + corepack

- `mise` lets the project bump or pin Node versions later (and other toolchains) via a single `.mise.toml` without rebuilding the image.
- `corepack` is the [official Node.js way](https://nodejs.org/api/corepack.html) to manage `pnpm`/`yarn` versions per project — pin via `packageManager` in `package.json` and corepack honors it.

The feature auto-installs mise if the [`mise` feature](https://github.com/alindesign/devcontainers/tree/main/src/mise) is not already present, so it works standalone.

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
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
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

- Installs `node`, `npm`, `npx`, plus the activated package manager as symlinks under `/usr/local/bin` so non-login shells (`RUN` steps, scripts, CI) see them without invoking mise.
- Interactive shells (bash, zsh) get `mise activate`, so `mise use node@20`, `mise install go@1.23`, etc. work inside the container.
- `MISE_DATA_DIR=/usr/local/share/mise` is world-writable so the remote user can install additional tools (this survives UID remapping that some test harnesses perform).
- Composes with the `dotfiles` feature — `dotfiles` writes its own `.zshrc` first, this feature appends mise activation idempotently.
