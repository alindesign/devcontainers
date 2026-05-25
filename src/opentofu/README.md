# opentofu

[OpenTofu](https://opentofu.org) — the open-source Terraform fork. Installed as a single binary at `/usr/local/bin/tofu`, with a `terraform` symlink for muscle memory.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | OpenTofu version (e.g. `1.8.4`). |
| `installTflint` | boolean | `true` | Install `tflint`. |

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/opentofu:1": {}
  }
}
```

## Notes

- `/usr/local/bin/terraform` is a symlink to `tofu`. Existing scripts that call `terraform` work without change.
- Module providers download into `.terraform/` per-project; nothing is cached system-wide.
