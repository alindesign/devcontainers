# Ansible (alindesign) — devcontainer template

- `ghcr.io/alindesign/devcontainer-base:latest` — Ubuntu base with `dotfiles` + `mise` pre-installed
- `ghcr.io/alindesign/features/python:1` — Python (mise + uv)
- `ghcr.io/alindesign/features/ansible:1` — Ansible + ansible-lint via `uv tool`

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/ansible:latest \
  --template-args '{"pythonVersion":"3.13","extraCollections":"community.general ansible.posix"}' \
  --workspace-folder .
```

Or, from VS Code: `Dev Containers: New Dev Container...` → `Ansible (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `pythonVersion` | `latest` | Python version (passed to the python feature). |
| `ansibleVersion` | `latest` | Ansible PyPI version. |
| `extraCollections` | `community.general ansible.posix` | Space-separated Galaxy collections installed for the remote user. |
| `gitUserName` | `""` | git user.name. |
| `gitUserEmail` | `""` | git user.email. |
