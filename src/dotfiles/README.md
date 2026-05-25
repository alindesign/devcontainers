# dotfiles

zsh + starship + modern CLI tools + neovim + sensible git defaults, layered on top of any Debian/Ubuntu-based devcontainer.

## What it installs

| Category | Tools |
| --- | --- |
| Shell | `zsh` (set as default for remote user), `starship` prompt |
| Listing | `eza` (aliased to `ls`/`ll`) |
| Search | `ripgrep` (`grep`), `fd-find` (`find`), `fzf` (keybindings + completion) |
| Files | `bat` (`cat`), `zoxide` (`cd`) |
| Git | `git-delta` (pager + interactive diff), curated `~/.gitconfig` |
| Editor | `neovim` with a minimal `init.lua` (numbers, 2-space indent, clipboard, `<space>` leader) |
| Misc | `jq`, `tmux`, `htop` |

Existing `~/.gitconfig` is preserved. Local overrides for zsh go in `~/.zshrc.local`.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `setDefaultShell` | boolean | `true` | `chsh` zsh for the remote user |
| `gitUserName` | string | `""` | sets `git config --global user.name` (skipped if empty) |
| `gitUserEmail` | string | `""` | sets `git config --global user.email` (skipped if empty) |
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

## Notes

- Requires a Debian/Ubuntu base image (apt-based).
- Architectures: `amd64`, `arm64`.
- `starship`, `eza`, `zoxide` are fetched as upstream binaries — apt versions are too old or absent.
- The feature is idempotent; running it twice does not duplicate config.
