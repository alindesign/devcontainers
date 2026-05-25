# Python (alindesign) — devcontainer template

- `mcr.microsoft.com/devcontainers/base:ubuntu`
- `ghcr.io/alindesign/features/dotfiles` — zsh, starship, CLI tools, git config
- `ghcr.io/alindesign/features/python:1` — Python via mise + configurable package manager (uv by default)

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/python:latest \
  --template-args '{"pythonVersion":"3.13","packageManager":"uv"}' \
  --workspace-folder .
```

Or, from VS Code: `Dev Containers: New Dev Container...` → `Python (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `pythonVersion` | `latest` | `latest`, major (`3.13`), or full version. |
| `packageManager` | `uv` | `uv`, `poetry`, or `none` (bare pip). |
| `gitUserName` | `""` | git user.name. |
| `gitUserEmail` | `""` | git user.email. |
