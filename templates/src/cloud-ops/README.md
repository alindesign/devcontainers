# Cloud Ops (alindesign) — devcontainer template

For DevOps / IaC / cloud scripting projects. Bundles AWS CLI v2 + gcloud CLI on top of dotfiles, with host credentials mounted in so `aws` and `gcloud` work without re-authenticating in the container.

- `mcr.microsoft.com/devcontainers/base:ubuntu`
- `ghcr.io/alindesign/features/dotfiles` — zsh, starship, CLI tools, git config
- `ghcr.io/alindesign/features/aws-cli:1` — AWS CLI v2
- `ghcr.io/alindesign/features/gcloud:1` — gcloud CLI (optional components via `gcloudComponents`)
- Host mounts:
  - `~/.aws` → `/home/vscode/.aws` (profiles, SSO sessions, credentials)
  - `~/.config/gcloud` → `/home/vscode/.config/gcloud` (logins, ADC, project/region)

## Prerequisite

`~/.aws` and `~/.config/gcloud` must exist on the host. Run `aws configure` and `gcloud auth login` once locally if they don't yet.

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/cloud-ops:latest \
  --template-args '{"gcloudComponents":"kubectl gke-gcloud-auth-plugin"}' \
  --workspace-folder .
```

Or, from VS Code: `Dev Containers: New Dev Container...` → `Cloud Ops (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `gcloudComponents` | `""` | Extra gcloud components installed via apt (or fallback to `gcloud components install`). |
| `gitUserName` | `""` | git user.name. |
| `gitUserEmail` | `""` | git user.email. |
