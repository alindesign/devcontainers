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
| Editor | `neovim` with a minimal `init.lua` (numbers, 2-space indent, clipboard, `<space>` leader) |
| Misc | `jq`, `tmux`, `htop` |
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
| `installNvim` | boolean | `true` | install neovim + minimal config |

## Use

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
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

## Notes

- Requires a Debian/Ubuntu base image (apt-based).
- Architectures: `amd64`, `arm64`.
- `starship`, `eza`, `zoxide` are fetched as upstream binaries — apt versions are too old or absent.
- The feature is idempotent; running it twice does not duplicate config.
