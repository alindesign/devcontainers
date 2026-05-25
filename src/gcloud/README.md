# gcloud

Installs [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) via Google's official apt repository.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `installComponents` | string | `""` | Space-separated components (e.g. `kubectl gke-gcloud-auth-plugin`). Installed as `google-cloud-cli-<name>` apt packages where available, falling back to `gcloud components install`. |

## Host mount

Mounts `~/.config/gcloud` from the host into `/home/vscode/.config/gcloud` so:

- `gcloud auth login` sessions on the host carry into the container
- ADC (Application Default Credentials) work without re-auth
- project/region/account settings persist across rebuilds

If your remote user is not `vscode`, override the mount in your project `devcontainer.json`.

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/gcloud:1": {
      "installComponents": "kubectl gke-gcloud-auth-plugin"
    }
  }
}
```
