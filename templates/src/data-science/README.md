# Data Science (alindesign) — devcontainer template

Quick-start for Python notebooks and ad-hoc data work.

- `dotfiles` — shell + CLI tools
- `python` with `uv` — fast project manager
- `db-tooling` (psql + mysql + redis, mongosh skipped) — for ingesting from external DBs
- `postCreateCommand` installs **JupyterLab** + **DuckDB** as user tools via `uv tool install`
- Port `8888` forwarded for Jupyter

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/alindesign/templates/data-science:latest \
  --template-args '{"pythonVersion":"3.13"}' \
  --workspace-folder .
```

Or from VS Code: `Dev Containers: New Dev Container...` → `Data Science (alindesign)`.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `pythonVersion` | `latest` | Python version. |
| `gitUserName` | `""` | git user.name. |
| `gitUserEmail` | `""` | git user.email. |

## Notes

- Jupyter and DuckDB are installed via `uv tool install` (each in its own venv under `${UV_TOOL_DIR}`). To add more, run `uv tool install pandas-cli`, etc., or use a project-level `pyproject.toml` with `uv add`.
- For ML stacks (torch / jax / sklearn), prefer a project `pyproject.toml` with `uv add` so versions are pinned per project rather than baked into the image.
