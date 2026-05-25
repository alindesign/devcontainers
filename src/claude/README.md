# claude

Installs [Anthropic's Claude Code CLI](https://docs.claude.com/en/docs/claude-code) globally via `npm install -g @anthropic-ai/claude-code`.

**Requires Node.js** — combine with the `node` feature (either `ghcr.io/alindesign/features/node` or `ghcr.io/devcontainers/features/node`).

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | npm version spec for `@anthropic-ai/claude-code`. |

## Host mount

The feature mounts `~/.claude` from the host into `/home/vscode/.claude` so that:

- the login session you have on the host carries into the container
- `claude` reads/writes the same conversation history and settings as your host install
- credentials live on the host, not in the image

If your remote user is not `vscode`, override the mount in your project `devcontainer.json`:

```jsonc
"mounts": [
  { "source": "${localEnv:HOME}/.claude", "target": "/home/myuser/.claude", "type": "bind" }
]
```

## Use

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/alindesign/features/node:1": {},
    "ghcr.io/alindesign/features/claude:1": {}
  },
  "remoteUser": "vscode"
}
```
