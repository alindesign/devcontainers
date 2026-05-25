# OCaml (alindesign) — devcontainer template

- `mcr.microsoft.com/devcontainers/base:ubuntu`
- `ghcr.io/alindesign/features/dotfiles` — zsh, starship, modern CLI tools, git config
- `ghcr.io/alindesign/features/ocaml:1` — OCaml via opam + dune + ocaml-lsp-server + ocamlformat

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/ocaml:latest \
  --template-args '{"ocamlVersion":"5.2.0"}' \
  --workspace-folder .
```

Or, from VS Code: `Dev Containers: New Dev Container...` → `OCaml (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `ocamlVersion` | `5.2.0` | OCaml compiler version for the default switch. |
| `gitUserName` | `""` | git user.name passed to dotfiles feature. |
| `gitUserEmail` | `""` | git user.email passed to dotfiles feature. |
