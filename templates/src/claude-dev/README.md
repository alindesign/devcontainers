# Claude Dev (alindesign) — devcontainer template

Bootstraps a `.devcontainer/devcontainer.json` for a project where you work with [Claude Code](https://docs.claude.com/en/docs/claude-code) inside a container. Your host login and history come along via bind mounts.

- `mcr.microsoft.com/devcontainers/base:ubuntu`
- `ghcr.io/alindesign/features/dotfiles` — zsh, starship, CLI tools, git config
- `ghcr.io/alindesign/features/node:2` — Node.js via mise + configurable package manager (pnpm by default)
- `ghcr.io/alindesign/features/claude:1` — Claude Code CLI
- Host mounts:
  - `~/.claude` → `/home/vscode/.claude` (sessions, settings, agents, history)
  - `~/.claude.json` → `/home/vscode/.claude.json` (per-machine state)
- `initializeCommand` on macOS: extracts the OAuth token from the host Keychain (`Claude Code-credentials` service) into `~/.claude/.credentials.json` so the mount carries it into the container. No-op on Linux/Windows.

## Prerequisite

`~/.claude` and `~/.claude.json` must exist on the host (run `claude` at least once locally to create them). On macOS, `claude login` stores the OAuth token in Keychain — this template dumps it to `~/.claude/.credentials.json` on every container start so Linux/container claude can read it.

If you'd rather not write the token to disk, drop the `initializeCommand`; you'll need to `claude login` inside the container instead (the result will persist in `~/.claude` via the mount).

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/claude-dev:latest \
  --template-args '{"nodeVersion":"lts","packageManager":"pnpm"}' \
  --workspace-folder .
```

Or, from VS Code: `Dev Containers: New Dev Container...` → `Claude Dev (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `nodeVersion` | `lts` | Node version (passed to the node feature). |
| `packageManager` | `pnpm` | `pnpm`, `npm`, `yarn`. |
| `gitUserName` | `""` | git user.name. |
| `gitUserEmail` | `""` | git user.email. |
