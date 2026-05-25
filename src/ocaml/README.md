# ocaml

OCaml via [`opam`](https://opam.ocaml.org). mise has no first-class OCaml plugin, so this feature uses opam directly with a shared `OPAMROOT` at `/usr/local/share/opam`.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `5.2.0` | OCaml compiler version for the default switch. |
| `installDuneAndLsp` | boolean | `true` | Also install `dune`, `ocaml-lsp-server`, `ocamlformat` into the switch. |

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/ocaml:1": { "version": "5.2.0" }
  }
}
```

## Notes

- `opam init --disable-sandboxing` is used because containerized `bwrap` often fails inside other containers. Sandboxing can be re-enabled later via `opam config set sandboxing true` if the host kernel allows it.
- `eval "$(opam env)"` is added to the remote user's bash/zsh rc so the switch's bin dir is on PATH for interactive shells.
