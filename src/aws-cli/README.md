# aws-cli

Installs [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) from the official zipped installer (not the apt package — that one ships v1).

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | `latest` or a pinned version like `2.18.0`. |

## Host mount

Mounts `~/.aws` from the host into `/home/vscode/.aws` so that:

- `aws configure` profiles you set up on the host are reused inside the container
- SSO sessions (`aws sso login`) and refresh tokens persist across rebuilds
- credentials live on the host filesystem, not in the image

If your remote user is not `vscode`, override the mount in your project `devcontainer.json`.

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/aws-cli:1": {}
  }
}
```
