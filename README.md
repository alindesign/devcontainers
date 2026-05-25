# devcontainers

Reusable [Dev Container Features](https://containers.dev/implementors/features/) and Templates published to `ghcr.io/alindesign`.

## Features

| Feature | ID | Purpose |
| --- | --- | --- |
| [dotfiles](src/dotfiles) | `ghcr.io/alindesign/features/dotfiles:1` | zsh + starship + CLI tools (fd, rg, bat, fzf, jq, delta, eza, zoxide) + nvim + git config |
| [mise](src/mise) | `ghcr.io/alindesign/features/mise:1` | [mise](https://mise.jdx.dev) toolchain manager, shared install at `/usr/local/share/mise` |
| [node](src/node) | `ghcr.io/alindesign/features/node:2` | Node.js via mise + package manager (pnpm/npm/yarn; pnpm default) |
| [go](src/go) | `ghcr.io/alindesign/features/go:1` | Go via mise, optional `go install` tools |
| [rust](src/rust) | `ghcr.io/alindesign/features/rust:1` | Rust via mise (rustup) with components + targets |
| [java](src/java) | `ghcr.io/alindesign/features/java:1` | Java (Temurin) via mise + optional Maven/Gradle |
| [ocaml](src/ocaml) | `ghcr.io/alindesign/features/ocaml:1` | OCaml via opam (mise has no first-class OCaml plugin) |
| [python](src/python) | `ghcr.io/alindesign/features/python:1` | Python via mise + uv (default) / poetry / pip |
| [ansible](src/ansible) | `ghcr.io/alindesign/features/ansible:1` | Ansible (+ ansible-lint) via uv tool. Auto-bootstraps Python. |
| [bun](src/bun) | `ghcr.io/alindesign/features/bun:1` | Bun runtime + package manager (standalone, no Node required) |
| [docker-in-docker](src/docker-in-docker) | `ghcr.io/alindesign/features/docker-in-docker:1` | Docker Engine + buildx + Compose v2 |
| [kubectl](src/kubectl) | `ghcr.io/alindesign/features/kubectl:1` | kubectl + helm + k9s + kubectx/kubens (each skippable) |
| [opentofu](src/opentofu) | `ghcr.io/alindesign/features/opentofu:1` | OpenTofu + tflint (with `terraform → tofu` alias) |
| [db-tooling](src/db-tooling) | `ghcr.io/alindesign/features/db-tooling:1` | CLI clients: psql + mysql + redis-cli + mongosh (each skippable) |
| [secrets](src/secrets) | `ghcr.io/alindesign/features/secrets:1` | sops + age + pass for secret management |
| [claude](src/claude) | `ghcr.io/alindesign/features/claude:1` | Claude Code CLI via npm. Bootstraps Node if missing. |
| [aws-cli](src/aws-cli) | `ghcr.io/alindesign/features/aws-cli:1` | AWS CLI v2 from the official installer |
| [gcloud](src/gcloud) | `ghcr.io/alindesign/features/gcloud:1` | gcloud CLI via Google apt repo (with components option) |

The mise-based features (`node`, `go`, `java`, `python`) all auto-bootstrap mise if you don't add the `mise` feature explicitly — they share the same `MISE_DATA_DIR` so adding more is incremental and cheap. `rust` uses rustup directly with system-wide `RUSTUP_HOME`/`CARGO_HOME`.

## Pre-built base image

If you find yourself always using `dotfiles` + `mise` together, skip the layer rebuild by using the pre-baked image:

```jsonc
{
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
  "features": {
    "ghcr.io/alindesign/features/node:2": { "packageManager": "pnpm" }
  }
}
```

See [images/base/](images/base) for what's included.

## Templates

| Template | ID | Stack |
| --- | --- | --- |
| [node](templates/src/node) | `ghcr.io/alindesign/templates/node` | Ubuntu + `dotfiles` + `node` (pnpm by default) |
| [go](templates/src/go) | `ghcr.io/alindesign/templates/go` | Ubuntu + `dotfiles` + `go` + gopls + dlv |
| [rust](templates/src/rust) | `ghcr.io/alindesign/templates/rust` | Ubuntu + `dotfiles` + `rust` (stable + clippy/rustfmt/rust-analyzer) |
| [java](templates/src/java) | `ghcr.io/alindesign/templates/java` | Ubuntu + `dotfiles` + `java` (Temurin 21) + Maven |
| [ocaml](templates/src/ocaml) | `ghcr.io/alindesign/templates/ocaml` | Ubuntu + `dotfiles` + `ocaml` (5.2.0 + dune + LSP) |
| [python](templates/src/python) | `ghcr.io/alindesign/templates/python` | Ubuntu + `dotfiles` + `python` (uv by default) |
| [ansible](templates/src/ansible) | `ghcr.io/alindesign/templates/ansible` | Ubuntu + `dotfiles` + `python` (uv) + `ansible` + `ansible-lint` |
| [claude-dev](templates/src/claude-dev) | `ghcr.io/alindesign/templates/claude-dev` | Ubuntu + `dotfiles` + `node` + `claude` + mounts `~/.claude` + `~/.claude.json` + macOS Keychain dump |
| [cloud-ops](templates/src/cloud-ops) | `ghcr.io/alindesign/templates/cloud-ops` | Ubuntu + `dotfiles` + `aws-cli` + `gcloud` + mounts `~/.aws` + `~/.config/gcloud` |
| [devops](templates/src/devops) | `ghcr.io/alindesign/templates/devops` | Full IaC toolbox: `dotfiles` + `python` + `ansible` + `aws-cli` + `gcloud` + `kubectl` + `opentofu` + `secrets` + mounts |
| [k8s](templates/src/k8s) | `ghcr.io/alindesign/templates/k8s` | Ubuntu + `dotfiles` + `go` + `kubectl` + `docker-in-docker` + mount `~/.kube` |
| [data-science](templates/src/data-science) | `ghcr.io/alindesign/templates/data-science` | Ubuntu + `dotfiles` + `python` (uv) + JupyterLab + DuckDB + db-tooling |

## Use in a new project

### From VS Code

`Dev Containers: New Dev Container...` → pick a template from `alindesign/...`.

### From CLI

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/node:latest \
  --workspace-folder .
```

### Manual `devcontainer.json` — compose features

Pick exactly what you need:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/alindesign/features/dotfiles:1": {},
    "ghcr.io/alindesign/features/node:2": { "packageManager": "pnpm" },
    "ghcr.io/alindesign/features/go:1": { "version": "1.23" },
    "ghcr.io/alindesign/features/claude:1": {},
    "ghcr.io/alindesign/features/aws-cli:1": {},
    "ghcr.io/alindesign/features/gcloud:1": {}
  },
  "remoteUser": "vscode"
}
```

Features that integrate with host-side accounts (`claude`, `aws-cli`, `gcloud`) declare static `mounts` in their manifest, so adding the feature automatically wires `~/.claude`, `~/.aws`, `~/.config/gcloud` from the host. The mount targets assume `remoteUser: vscode`; override in your `devcontainer.json` if you use a different user.

## Repo layout

```
src/                       features (one folder per feature)
test/                      `devcontainer features test` scenarios
templates/src/             devcontainer templates
.github/workflows/         release + CI
```

## Local development

```bash
# Test a single feature
devcontainer features test --features node --base-image mcr.microsoft.com/devcontainers/base:ubuntu .

# Test a template (only after publishing — CLI needs an OCI ref, not a path)
devcontainer templates apply -t ghcr.io/alindesign/templates/node:latest -w /tmp/scratch
```

Requires the [`devcontainer` CLI](https://github.com/devcontainers/cli):

```bash
brew install devcontainer
# or
npm install -g @devcontainers/cli
```

## Release

Every push to `main` triggers `.github/workflows/release.yml`, which publishes any changed features and templates to `ghcr.io/alindesign/...` (versions come from each feature/template manifest).

```bash
# Bump a feature's version, then:
git commit -am "feat(node): ..."
git push
```
