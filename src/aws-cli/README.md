# aws-cli

Installs [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) from the official zipped installer (not the apt package — that one ships v1).

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | `latest` or a pinned version like `2.18.0`. |

## Host mount (recommended)

Add this to your `devcontainer.json` so host profiles, SSO sessions, and credentials are reused inside the container:

```jsonc
"mounts": [
  { "source": "${localEnv:HOME}/.aws", "target": "/home/vscode/.aws", "type": "bind" }
]
```

Not declared in the feature manifest because the bind mount would fail at container startup on hosts without an `~/.aws` directory (CI runners, fresh machines). Adding it in your project devcontainer is opt-in.

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/aws-cli:1": {}
  }
}
```
