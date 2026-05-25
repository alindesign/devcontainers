# mise

System-wide install of [mise](https://mise.jdx.dev) — a polyglot toolchain version manager. Other features in this repo (`node`, `go`, `rust`, `java`) install their runtimes via mise on top of this.

## What it installs

- `mise` binary at `/usr/local/bin/mise`
- Shared data dir at `/usr/local/share/mise` (group-writable for the remote user, world-writable to survive UID remap)
- `MISE_DATA_DIR` exported via `/etc/profile.d/mise.sh`
- `mise activate` added to the remote user's `~/.bashrc` (and `~/.zshrc` if zsh is present)

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | `latest` or a pinned mise version (`2024.11.0`). |
| `autoActivate` | boolean | `true` | Inject `mise activate` into the remote user's bash/zsh rc. |

## Use

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/alindesign/features/mise:1": {}
  }
}
```

Once installed, manage tools per-project with a `.mise.toml`:

```toml
[tools]
node = "22"
go = "1.23"
rust = "stable"
```

## Notes

- The `node`, `go`, `rust`, `java` features here all build on `mise` and skip re-installing it if already present.
- Composes cleanly with the `dotfiles` feature — `dotfiles` writes its own `.zshrc` first, and this feature appends mise activation idempotently.
