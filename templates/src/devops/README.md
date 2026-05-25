# DevOps (alindesign) — devcontainer template

The full IaC + DevOps toolbox in one container.

- `ghcr.io/alindesign/devcontainer-base:latest` — Ubuntu base with `dotfiles` + `mise` pre-installed
- `python` (uv) — for ansible & scripting
- `ansible` (+ ansible-lint) — playbooks
- `aws-cli` + host mount `~/.aws`
- `gcloud` + host mount `~/.config/gcloud` (+ optional components)
- `kubectl` + helm + k9s + kubectx + host mount `~/.kube`
- `opentofu` (+ tflint) — alias `terraform → tofu`
- `secrets` — sops + age + pass

## Prerequisite

`~/.aws`, `~/.config/gcloud`, `~/.kube` must exist on the host. Run their respective CLIs once locally to create them if missing.

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/devops:latest \
  --template-args '{"gcloudComponents":"kubectl gke-gcloud-auth-plugin"}' \
  --workspace-folder .
```

Or from VS Code: `Dev Containers: New Dev Container...` → `DevOps (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `pythonVersion` | `latest` | Python version (drives `ansible`'s uv-based install too). |
| `kubectlVersion` | `latest` | kubectl version. |
| `gcloudComponents` | `""` | Extra gcloud components. |
| `gitUserName` | `""` | git user.name. |
| `gitUserEmail` | `""` | git user.email. |
