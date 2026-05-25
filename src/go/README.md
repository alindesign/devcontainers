# go

Go via [mise](https://mise.jdx.dev). Auto-bootstraps mise if the [`mise` feature](https://github.com/alindesign/devcontainers/tree/main/src/mise) is not present.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | `latest`, major (`1.23`), or full (`1.23.4`). |
| `installTools` | string | `""` | Space-separated `go install` specs (e.g. `golang.org/x/tools/gopls@latest github.com/go-delve/delve/cmd/dlv@latest`). |

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/go:1": {
      "version": "1.23",
      "installTools": "golang.org/x/tools/gopls@latest github.com/go-delve/delve/cmd/dlv@latest"
    }
  }
}
```

`$HOME/go/bin` is added to the remote user's PATH so installed tools are picked up.
