# ansible

Installs [Ansible](https://docs.ansible.com) (and optionally [ansible-lint](https://ansible.readthedocs.io/projects/lint/)) via `uv tool install` — falls back to `pipx` if uv is not available. Auto-bootstraps Python + uv if no Python is present, so the feature works standalone.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | PyPI version of `ansible`. `latest` tracks upstream. |
| `installLint` | boolean | `true` | Also install `ansible-lint` as a separate uv tool. |
| `extraCollections` | string | `""` | Space-separated Galaxy collections to install for the remote user (e.g. `community.general ansible.posix`). |

## Use

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/alindesign/features/python:1": { "packageManager": "uv" },
    "ghcr.io/alindesign/features/ansible:1": {
      "installLint": true,
      "extraCollections": "community.general ansible.posix"
    }
  }
}
```

Or standalone (bootstrap Python automatically):

```jsonc
"features": {
  "ghcr.io/alindesign/features/ansible:1": {}
}
```

## Notes

- Tools live under `/usr/local/share/uv/tools/<tool>/bin/<binary>` with symlinks in `/usr/local/bin`. Both `ansible` and `ansible-lint` get their own isolated venv (uv tool convention).
- Galaxy collections are installed for the remote user (so they land in `~/.ansible/collections`), not system-wide.
- `UV_TOOL_DIR=/usr/local/share/uv/tools` is exported when uv is the installer, so `uv tool list` / `uv tool upgrade` work for any user without setup.
