# Rust (alindesign) — devcontainer template

- `mcr.microsoft.com/devcontainers/base:ubuntu`
- `ghcr.io/alindesign/features/dotfiles` — zsh, starship, modern CLI tools, git config
- `ghcr.io/alindesign/features/rust:1` — Rust via mise (rustup) with `clippy rustfmt rust-analyzer`

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/rust:latest \
  --template-args '{"rustVersion":"stable","targets":"wasm32-unknown-unknown"}' \
  --workspace-folder .
```

Or, from VS Code: `Dev Containers: New Dev Container...` → `Rust (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `rustVersion` | `stable` | `stable`, `nightly`, `beta`, or pinned (`1.83`). |
| `targets` | `""` | Space-separated `rustup target add` list. |
| `gitUserName` | `""` | git user.name passed to dotfiles feature. |
| `gitUserEmail` | `""` | git user.email passed to dotfiles feature. |
