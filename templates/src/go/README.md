# Go (alindesign) — devcontainer template

- `mcr.microsoft.com/devcontainers/base:ubuntu`
- `ghcr.io/alindesign/features/dotfiles` — zsh, starship, modern CLI tools, git config
- `ghcr.io/alindesign/features/go:1` — Go via mise

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/go:latest \
  --template-args '{"goVersion":"1.23"}' \
  --workspace-folder .
```

Or, from VS Code: `Dev Containers: New Dev Container...` → `Go (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `goVersion` | `latest` | Go version. `latest`, major (`1.23`), or full. |
| `installTools` | `gopls + dlv` | Space-separated `go install` specs installed at build time. |
| `gitUserName` | `""` | git user.name passed to dotfiles feature. |
| `gitUserEmail` | `""` | git user.email passed to dotfiles feature. |
