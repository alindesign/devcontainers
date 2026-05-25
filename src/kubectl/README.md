# kubectl

`kubectl` + `helm` + `k9s` + `kubectx` / `kubens`. Each addon can be skipped via the `installX` options.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `kubectlVersion` | string | `latest` | `latest` (dl.k8s.io stable) or a pinned version (`v1.31.0` / `1.31.0`). |
| `helmVersion` | string | `latest` | `latest` (get-helm-3 script) or pinned (`v3.16.2`). |
| `installHelm` | boolean | `true` | Install Helm. |
| `installK9s` | boolean | `true` | Install k9s TUI. |
| `installKubectx` | boolean | `true` | Install `kubectx` + `kubens`. |

## Host mount (recommended)

```jsonc
"mounts": [
  { "source": "${localEnv:HOME}/.kube", "target": "/home/vscode/.kube", "type": "bind" }
]
```

Not declared in the feature manifest because bind mounts fail at container startup when the host dir doesn't exist (CI runners). Use the [`k8s`](../../templates/src/k8s) template if you want this baked in.

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/kubectl:1": {
      "installK9s": false
    }
  }
}
```
