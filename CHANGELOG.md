# Changelog

All notable changes to this repo's Dev Container Features and Templates are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); each feature and template has its own SemVer in `devcontainer-feature.json` / `devcontainer-template.json`.

## [Unreleased]

## 2026-05-25

### Added — Features
- `dotfiles` 1.1.0 — optional GPG / SSH commit signing (`gitSigningFormat` + `gitSigningKey`).
- `mise` 1.0.1 — system-wide toolchain manager. Shims dir auto-exported on PATH via `/etc/profile.d/mise.sh`.
- `node` 2.0.1 — rewritten on top of mise (was nvm in 1.x). `packageManager` option (`pnpm` default, `npm`, `yarn`, `none`).
- `go` 1.0.1, `java` 1.0.1, `rust` 1.0.1 — language toolchains.
- `ocaml` 1.0.1 — opam-based, shared `OPAMROOT` at `/usr/local/share/opam`.
- `python` 1.0.0 — Python via mise. `packageManager` option (`uv` default, `poetry`, `none`).
- `ansible` 1.0.0 — Ansible + ansible-lint via `uv tool install`. Bootstraps Python if missing.
- `claude` 1.0.1 — Claude Code CLI via npm. Bootstraps Node if missing.
- `aws-cli` 1.0.1 — official AWS CLI v2 installer.
- `gcloud` 1.0.1 — Google Cloud CLI via apt with optional components.

### Added — Templates
- `node` 1.0.0 — Node project starter (dotfiles + node).
- `go`, `rust`, `java`, `ocaml` 1.0.0 — per-language starters.
- `python` 1.0.0 — Python (dotfiles + python with uv default).
- `ansible` 1.0.0 — Ansible playbook authoring (dotfiles + python + ansible).
- `claude-dev` 1.0.0 — Node + Claude Code. Mounts host `~/.claude` + `~/.claude.json`. `initializeCommand` on macOS dumps OAuth token from Keychain into the mount so the container is authenticated automatically.
- `cloud-ops` 1.0.0 — AWS + GCP tooling with host credential mounts.

### Fixed
- `node` 2.0.1 — pin tool versions in `/etc/mise/config.toml` (system-wide), use mise shims dir on PATH. Direct symlinks to mise installs broke `npm` because it resolves its lib relative to `argv[0]`.
- `rust` 1.0.1 — switched from mise to direct rustup install with `RUSTUP_HOME` / `CARGO_HOME` pinned system-wide. mise's rust plugin stored the toolchain under the invoking user's `$HOME`, breaking across container users.
- `ocaml` 1.0.1 — `chown OPAMROOT` to the remote user *before* `opam init`, so init writes the sandbox hooks as the right owner.
- `dotfiles` 1.1.0 — pinned versions for `eza`/`zoxide` direct downloads (upstream installers query the GitHub API and hit anonymous rate limits in CI).
- `aws-cli` 1.0.1, `gcloud` 1.0.1, `claude` 1.0.1 — dropped `mounts` from feature manifests; bind mounts fail at container startup if the host dir doesn't exist (CI runners, fresh machines). Manifests now document how to add the mount manually, and the `claude-dev` / `cloud-ops` templates include them.

[Unreleased]: https://github.com/alindesign/devcontainers/compare/main...HEAD
