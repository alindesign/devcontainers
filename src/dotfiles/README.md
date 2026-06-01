# dotfiles

zsh + starship + modern CLI tools + neovim + sensible git defaults, with optional commit signing (GPG or SSH), layered on top of any Debian/Ubuntu-based devcontainer.

## What it installs

| Category | Tools |
| --- | --- |
| Shell | `zsh` (set as default for remote user), `starship` prompt |
| Listing | `eza` (aliased to `ls`/`ll`) |
| Search | `ripgrep` (`grep`), `fd-find` (`find`), `fzf` (keybindings + completion) |
| Files | `bat` (`cat`), `zoxide` (`cd`) |
| Git | `git-delta` (pager + interactive diff), curated `~/.gitconfig`, optional GPG/SSH signing |
| GitHub | `gh` CLI from the official apt repo, wired as the git credential helper for `github.com` / `gist.github.com` |
| History | `atuin` — encrypted, syncable shell history with a fuzzy Ctrl-R UI (up-arrow keeps native zsh history) |
| Editor | `neovim` (recent build from upstream tarball) + alindesign [LazyVim](https://www.lazyvim.org/) config sourced from [alindesign/dotfiles](https://github.com/alindesign/dotfiles) + treesitter build deps (`gcc`, `make`) |
| Multiplexer | `tmux` + alindesign `~/.tmux.conf` (`C-a` prefix, vi mode, mouse, catppuccin status line) + TPM pre-bootstrapped with `tmux-cpu`, `tmux-battery`, `catppuccin/tmux` |
| Misc | `jq`, `htop` |
| Signing (opt-in) | `gnupg2` (if `gitSigningFormat=gpg`) — skipped for `ssh` and `none` |

Existing `~/.gitconfig` is preserved. Local overrides for zsh go in `~/.zshrc.local`.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `setDefaultShell` | boolean | `true` | `chsh` zsh for the remote user |
| `gitUserName` | string | `""` | sets `git config --global user.name` (skipped if empty) |
| `gitUserEmail` | string | `""` | sets `git config --global user.email` (skipped if empty) |
| `gitSigningFormat` | string | `gpg` | `gpg`, `ssh`, or `none`. `gpg` installs gnupg + sets pinentry to loopback. `ssh` configures git for SSH signing and skips gnupg. |
| `gitSigningKey` | string | `""` | GPG key ID/fingerprint, or absolute path to a public SSH key inside the container. Empty leaves signing off even when format is set. |
| `installNvim` | boolean | `true` | install recent neovim (upstream tarball) + alindesign LazyVim config + treesitter build deps (`gcc`, `make`). Set false to skip. |
| `installGhCli` | boolean | `true` | install `gh` from `cli.github.com/packages` and set it as the git credential helper for github.com + gist.github.com |
| `installAtuin` | boolean | `true` | install `atuin` and wire `atuin init zsh --disable-up-arrow` into `~/.zshrc` (Ctrl-R only — up-arrow stays native zsh history) |
| `atuinSyncAddress` | string | `""` | atuin sync server URL (e.g. `https://atuin.example.com`). Empty leaves the upstream default. Set this so `atuin login` hits the right backend without editing the toml manually. |
| `installTmuxConfig` | boolean | `true` | write the alindesign `~/.tmux.conf` and pre-bootstrap TPM + plugins (`tmux-cpu`, `tmux-battery`, `catppuccin/tmux`). tmux itself is always installed. |

## Use

```jsonc
{
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
  "features": {
    "ghcr.io/alindesign/features/dotfiles:1": {
      "gitUserName": "Your Name",
      "gitUserEmail": "you@example.com"
    }
  },
  "remoteUser": "vscode"
}
```

## Commit signing

### Option A — GPG (host key reused via mount)

Set `gitSigningFormat: gpg` (default) and `gitSigningKey` to your GPG key ID, then mount your host `~/.gnupg` so the private key never leaves the host:

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/dotfiles:1": {
      "gitUserName": "Your Name",
      "gitUserEmail": "you@example.com",
      "gitSigningKey": "0xABCDEF0123456789"
    }
  },
  "mounts": [
    { "source": "${localEnv:HOME}/.gnupg", "target": "/home/vscode/.gnupg", "type": "bind" }
  ]
}
```

The feature configures `pinentry-mode loopback` + `allow-loopback-pinentry` and exports `GPG_TTY` so `git commit -S` works inside the container without a graphical pinentry. The mount is **not** declared in the feature manifest because bind mounts fail at startup if the host directory doesn't exist (CI runners, fresh machines).

### Option B — SSH signing

Set `gitSigningFormat: ssh` and `gitSigningKey` to the absolute container path of your public SSH key. Mount `~/.ssh` so the matching private key is reachable:

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/dotfiles:1": {
      "gitUserName": "Your Name",
      "gitUserEmail": "you@example.com",
      "gitSigningFormat": "ssh",
      "gitSigningKey": "/home/vscode/.ssh/id_ed25519.pub"
    }
  },
  "mounts": [
    { "source": "${localEnv:HOME}/.ssh", "target": "/home/vscode/.ssh", "type": "bind", "readonly": true }
  ]
}
```

`gnupg` is not installed in this mode. The feature also sets `gpg.ssh.allowedSignersFile=~/.config/git/allowed_signers` — populate it manually with `<email> <pubkey>` lines if you want `git log --show-signature` to verify locally.

### Option C — no signing

`gitSigningFormat: none` (or leaving `gitSigningKey` empty) skips signing setup entirely.

## GitHub CLI

`gh` is installed from `https://cli.github.com/packages` and registered as the git credential helper for `github.com` and `gist.github.com`. Auth is not done automatically — run `gh auth login` once inside the container (or mount the host's `~/.config/gh` to reuse an existing token). Once authed, `git push` / `git clone` against GitHub will pick up credentials from `gh` with no extra config.

Set `installGhCli: false` to skip the install and leave the credential helper unconfigured.

## Atuin (shell history)

`atuin` replaces `Ctrl-R` with a fuzzy, full-text search over an SQLite-backed history shared across every shell session. Up-arrow is left alone (`--disable-up-arrow`) so muscle memory still works.

A starter config is written to `~/.config/atuin/config.toml` only if you don't already have one — `enter_accept = false` (Tab moves a selected entry to the prompt instead of executing it), compact UI, daemon off. Override anything by editing the file or dropping a complete config from a chezmoi/mount.

For cross-host sync, run once inside the container:

```bash
atuin register -u <username> -e <email>   # new account
# or
atuin login -u <username>                  # existing account
atuin sync                                 # initial pull/push
```

Self-hosters: add `sync_address = "https://your-atuin-server"` to the config.

Set `installAtuin: false` to skip the install entirely (no binary, no zshrc line).

To target a self-hosted atuin server without hand-editing `~/.config/atuin/config.toml`, pass `atuinSyncAddress`:

```jsonc
"features": {
  "ghcr.io/alindesign/features/dotfiles:1": {
    "atuinSyncAddress": "https://atuin.your-domain.com"
  }
}
```

## tmux

`tmux` is always installed via apt. With `installTmuxConfig: true` (default) the feature seeds the alindesign tmux setup (sourced from [alindesign/dotfiles](https://github.com/alindesign/dotfiles)):

- `C-a` prefix (`C-b` unbound)
- `|` / `-` for horizontal/vertical splits, both inheriting the current pane's cwd
- `c` opens a new window in the current pane's cwd
- vi mode + `v`/`y` selection in copy-mode
- mouse on, base-index 1, automatic window renaming + renumbering
- `r` reloads the config, `S` toggles pane sync
- TPM (Tmux Plugin Manager) cloned to `~/.tmux/plugins/tpm` and `tmux-cpu` / `tmux-battery` / `catppuccin/tmux` plugins pre-installed — the catppuccin status line works on the first attach, no `prefix + I` required

Set `installTmuxConfig: false` to install tmux but skip writing the config (e.g. if you mount your host `~/.tmux.conf`).

## neovim

`installNvim: true` (default) installs a recent neovim from the upstream tarball (apt's nvim is too old for LazyVim) and seeds `~/.config/nvim` with the alindesign LazyVim setup from [alindesign/dotfiles](https://github.com/alindesign/dotfiles): full `lua/config` (options, keymaps, autocmds, lazy.lua), `lazyvim.json` extras (rust/python/go/typescript/docker/terraform/ansible/etc.), and the personal plugin set under `lua/plugins` (catppuccin theme, claudecode, oil, aerial, harpoon, smart-splits, devcontainer.nvim, chezmoi.nvim, …). `gcc` + `make` are pulled in so nvim-treesitter can compile parsers on first run.

First nvim start auto-bootstraps `lazy.nvim` and downloads all plugins. To pre-warm at build time, add a `postCreateCommand` to your `devcontainer.json`:

```jsonc
"postCreateCommand": "nvim --headless '+Lazy! sync' +qa"
```

Want a different nvim setup? Set `installNvim: false` and either layer your own feature, install nvim yourself in a `postCreateCommand`, or mount your host config:

```jsonc
"mounts": [
  { "source": "${localEnv:HOME}/.config/nvim", "target": "/home/vscode/.config/nvim", "type": "bind", "readonly": true }
]
```

## Notes

- Requires a Debian/Ubuntu base image (apt-based).
- Architectures: `amd64`, `arm64`.
- `starship`, `eza`, `zoxide`, `atuin` are fetched as upstream binaries — apt versions are too old or absent.
- The feature is idempotent; running it twice does not duplicate config.
