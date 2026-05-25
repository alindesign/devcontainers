# secrets

Secret management tooling: [sops](https://github.com/getsops/sops), [age](https://github.com/FiloSottile/age), and optionally [pass](https://www.passwordstore.org).

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `sopsVersion` | string | `latest` | sops release tag (e.g. `v3.9.1`). `latest` resolves to a known-good pin. |
| `ageVersion` | string | `latest` | age release tag (e.g. `v1.2.0`). |
| `installPass` | boolean | `true` | Install `pass` + `gnupg2`. |

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/secrets:1": {}
  }
}
```

## Host mount (GPG, optional)

`pass` and `sops`'s GPG provider need access to your GPG keyring. Mount it from host:

```jsonc
"mounts": [
  { "source": "${localEnv:HOME}/.gnupg", "target": "/home/vscode/.gnupg", "type": "bind" }
]
```

(See the `dotfiles` feature for the matching GPG signing setup.)
