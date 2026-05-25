# claude

Installs [Anthropic's Claude Code CLI](https://docs.claude.com/en/docs/claude-code) globally via `npm install -g @anthropic-ai/claude-code`.

**Requires Node.js** — combine with the `node` feature (either `ghcr.io/alindesign/features/node` or `ghcr.io/devcontainers/features/node`).

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | npm version spec for `@anthropic-ai/claude-code`. |

## Host mount (recommended)

Add this to your `devcontainer.json` so your host login carries into the container, claude reads/writes the same history/settings, and credentials stay on the host (not baked into the image):

```jsonc
"mounts": [
  { "source": "${localEnv:HOME}/.claude", "target": "/home/vscode/.claude", "type": "bind" }
]
```

This isn't declared in the feature manifest because `bind` mounts fail at startup if the host directory doesn't exist (which would break CI runners and any host without a prior `claude` login). Adding it manually in your project's `devcontainer.json` is opt-in.

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
