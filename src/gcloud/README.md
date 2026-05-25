# gcloud

Installs [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) via Google's official apt repository.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `installComponents` | string | `""` | Space-separated components (e.g. `kubectl gke-gcloud-auth-plugin`). Installed as `google-cloud-cli-<name>` apt packages where available, falling back to `gcloud components install`. |

## Host mount (recommended)

Add this to your `devcontainer.json` so host login, ADC, and project/region settings are reused inside the container:

```jsonc
"mounts": [
  { "source": "${localEnv:HOME}/.config/gcloud", "target": "/home/vscode/.config/gcloud", "type": "bind" }
]
```

Not declared in the feature manifest because the bind mount would fail at container startup on hosts without `~/.config/gcloud` (CI runners, fresh machines). Adding it in your project devcontainer is opt-in.

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
