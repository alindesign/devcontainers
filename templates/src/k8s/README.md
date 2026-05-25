# Kubernetes (alindesign) — devcontainer template

For Kubernetes controller / operator dev and local cluster work.

- `dotfiles` — shell + CLI tools
- `go` — most controller toolchains
- `kubectl` + helm + k9s + kubectx
- `docker-in-docker` — spin up `kind` / `k3d` / `minikube` from inside the container
- Host mount `~/.kube` — reuse host kubeconfigs

## Prerequisite

`~/.kube` must exist on the host. Run `kubectl` once locally if missing.

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/k8s:latest \
  --workspace-folder .
```

Or from VS Code: `Dev Containers: New Dev Container...` → `Kubernetes (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `goVersion` | `latest` | Go version. |
| `kubectlVersion` | `latest` | kubectl version. |
| `gitUserName` | `""` | git user.name. |
| `gitUserEmail` | `""` | git user.email. |

## Local clusters

Inside the container:

```bash
# kind
go install sigs.k8s.io/kind@latest
kind create cluster

# k3d
curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d cluster create
```
