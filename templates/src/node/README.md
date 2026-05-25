# Node.js (alindesign) — devcontainer template

Bootstraps a `.devcontainer/devcontainer.json` for a Node.js project with:

- `ghcr.io/alindesign/devcontainer-base:latest` — Ubuntu base with `dotfiles` + `mise` pre-installed
- `ghcr.io/alindesign/features/node:2` — Node (LTS) via mise + configurable package manager (pnpm by default)

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/node:latest \
  --template-args '{"nodeVersion":"lts","packageManager":"pnpm"}' \
  --workspace-folder .
```

Or, from VS Code: `Dev Containers: New Dev Container...` → `Node.js (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `nodeVersion` | `lts` | Node version. `lts`, `latest`, major (e.g. `22`), or full version. |
| `packageManager` | `pnpm` | One of `pnpm`, `npm`, `yarn`. |
| `gitUserName` | `""` | git user.name passed to dotfiles feature. |
| `gitUserEmail` | `""` | git user.email passed to dotfiles feature. |
