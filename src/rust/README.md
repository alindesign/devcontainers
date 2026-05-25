# rust

Rust toolchain via [`rustup`](https://rustup.rs), with `RUSTUP_HOME=/usr/local/rustup` and `CARGO_HOME=/usr/local/cargo` pinned system-wide so the toolchain is shared across all container users (and survives UID remapping in CI / dev container test harnesses).

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

`CARGO_HOME/bin` is exported on the global PATH via `/etc/profile.d/rust.sh`. Binaries (`cargo`, `rustc`, `rustup`, etc.) are also symlinked into `/usr/local/bin` so non-login shells (RUN steps, CI) pick them up without sourcing profile.

`cargo install` writes into `${CARGO_HOME}/bin` (system-wide). If you want per-user crate installs, override `CARGO_INSTALL_ROOT=$HOME/.cargo` in your project.
