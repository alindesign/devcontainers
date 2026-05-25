# python

Python via [mise](https://mise.jdx.dev), with a configurable package/project manager. [uv](https://docs.astral.sh/uv/) is the default; [poetry](https://python-poetry.org) and `none` (bare pip) are supported.

The feature auto-installs mise if the [`mise` feature](https://github.com/alindesign/devcontainers/tree/main/src/mise) is not already present, so it works standalone.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | `latest`, major (`3.13`), or full (`3.13.1`). Passed to mise. |
| `packageManager` | string | `uv` | One of `uv`, `poetry`, `none`. |
| `packageManagerVersion` | string | `latest` | Version pin for uv/poetry. Ignored when `packageManager` is `none`. |

## Use

```jsonc
{
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
  "features": {
    "ghcr.io/alindesign/features/python:1": {
      "version": "3.13",
      "packageManager": "uv"
    }
  }
}
```

Switch to poetry:

```jsonc
"ghcr.io/alindesign/features/python:1": { "packageManager": "poetry", "packageManagerVersion": "1.8.4" }
```

Bare Python + pip:

```jsonc
"ghcr.io/alindesign/features/python:1": { "packageManager": "none" }
```

## Notes

- `python`, `python3`, `pip`, `pip3` are exposed via `/usr/local/bin` (mise shims) so non-login shells see them.
- `uv` lives at `/usr/local/bin/uv` (single binary from Astral's installer).
- `poetry` lives under `/usr/local/poetry/bin/poetry` with a symlink at `/usr/local/bin/poetry`.
- Build deps for compiling Python from source are installed (mise prefers prebuilt binaries, but compile fallback works on older platforms).
- Composes cleanly with the `dotfiles` feature — `dotfiles` writes its own `.zshrc` first, this feature appends mise activation idempotently.
