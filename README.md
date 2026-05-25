# devcontainers

Reusable [Dev Container Features](https://containers.dev/implementors/features/) and Templates published to `ghcr.io/alindesign`.

## Features

| Feature | ID | Purpose |
| --- | --- | --- |
| dotfiles | `ghcr.io/alindesign/features/dotfiles:1` | zsh + starship + CLI tools (fd, rg, bat, fzf, jq, delta, eza, zoxide) + nvim + git config |
| node | `ghcr.io/alindesign/features/node:1` | Node.js (LTS by default) via `nvm` + configurable package manager (pnpm/npm/yarn; pnpm default) |

## Templates

| Template | ID | Stack |
| --- | --- | --- |
| node | `ghcr.io/alindesign/templates/node` | Ubuntu + `dotfiles` + `node` (pnpm by default) |

## Use in a new project

### From VS Code

`Dev Containers: New Dev Container...` → pick `alindesign/node`.

### From CLI

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/node:latest \
  --workspace-folder .
```

### Manual `devcontainer.json`

Compose features on any base image:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/alindesign/features/dotfiles:1": {},
    "ghcr.io/alindesign/features/node:1": { "version": "lts", "packageManager": "pnpm" }
  },
  "remoteUser": "vscode"
}
```

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
devcontainer features test --features dotfiles --base-image mcr.microsoft.com/devcontainers/base:ubuntu .

# Test a template
devcontainer templates apply -t ./templates/src/node -w /tmp/scratch
```

Requires the [`devcontainer` CLI](https://github.com/devcontainers/cli): `brew install devcontainer` (already in `../dotfiles/dot_Brewfile`).

## Release

Tag a release, GH Actions publishes features and templates to `ghcr.io/alindesign/...`.

```bash
git tag v1.0.0 && git push --tags
```
