# rust

Rust toolchain via [mise](https://mise.jdx.dev) (which uses `rustup` under the hood). Auto-bootstraps mise if not present.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `stable` | `stable`, `nightly`, `beta`, or a pinned version (`1.83`). |
| `components` | string | `clippy rustfmt rust-analyzer` | Space-separated `rustup component add` list. |
| `targets` | string | `""` | Space-separated `rustup target add` list (e.g. `wasm32-unknown-unknown`). |

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/rust:1": {
      "version": "stable",
      "targets": "wasm32-unknown-unknown"
    }
  }
}
```

`$HOME/.cargo/bin` is added to the remote user's PATH so `cargo install` works as expected.
