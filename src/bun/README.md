# bun

[Bun](https://bun.sh) — JavaScript runtime + package manager + bundler. Single static binary at `/usr/local/bun/bin/bun`, system-wide.

Standalone — does not require Node. If you want both, add the `node` feature too.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | `latest`, `canary`, or a tagged version (e.g. `1.1.34`). |

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/bun:1": {}
  }
}
```

Combined with Node (e.g. when you need both runtimes side-by-side):

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/node:2": { "packageManager": "pnpm" },
    "ghcr.io/alindesign/features/bun:1": {}
  }
}
```

## Notes

- `bun` and `bunx` are exposed via `/usr/local/bin`.
- `BUN_INSTALL=/usr/local/bun` is exported via `/etc/profile.d/bun.sh` and the user's rc files, so `bun add -g ...` puts binaries somewhere all users can reach.
- World-writable on `/usr/local/bun` to survive UID remap (same rationale as `node` feature).
