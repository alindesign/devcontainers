# devcontainer-base

Pre-built devcontainer base image with `dotfiles` + `mise` baked in.

- **Image**: `ghcr.io/alindesign/devcontainer-base`
- **Tags**: `latest`, `ubuntu` (mirrors `mcr.microsoft.com/devcontainers/base:ubuntu`)
- **Architectures**: `linux/amd64`, `linux/arm64`

## Use

```jsonc
{
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
  "features": {
    "ghcr.io/alindesign/features/node:2": { "packageManager": "pnpm" }
  },
  "remoteUser": "vscode"
}
```

Skip explicit `dotfiles` and `mise` features — they're already in the image. Adding them again is idempotent (no-op) but wastes build time.

## Why

The `dotfiles` feature installs ~15 apt packages + 3 binary downloads (~30s steady state). `mise` adds another bootstrap. Pre-baking saves ~1-2 min per `devcontainer up` on cold caches.

For maximum freshness, prefer composing features in your project's devcontainer.json — this image is a convenience for stable, oft-used combos.

## Source

Built from this repo's `images/base/Dockerfile`, published by `.github/workflows/build-base-image.yml` on every push to `main`.
