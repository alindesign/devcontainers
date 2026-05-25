# Java (alindesign) — devcontainer template

- `ghcr.io/alindesign/devcontainer-base:latest` — Ubuntu base with `dotfiles` + `mise` pre-installed
- `ghcr.io/alindesign/features/java:1` — Java via mise + optional Maven/Gradle

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/java:latest \
  --template-args '{"javaVersion":"temurin-21","installMaven":"true"}' \
  --workspace-folder .
```

Or, from VS Code: `Dev Containers: New Dev Container...` → `Java (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `javaVersion` | `temurin-21` | mise java spec (`temurin-21`, `corretto-17`, `openjdk-21`, `21`). |
| `installMaven` | `true` | Install Maven via mise. |
| `installGradle` | `false` | Install Gradle via mise. |
| `gitUserName` | `""` | git user.name passed to dotfiles feature. |
| `gitUserEmail` | `""` | git user.email passed to dotfiles feature. |
