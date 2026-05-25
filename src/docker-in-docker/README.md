# docker-in-docker

Docker Engine (CE) + buildx + Compose v2 inside the container. The daemon starts lazily via `/usr/local/share/docker-init.sh` on container creation.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `latest` | Docker Engine version (e.g. `24.0`). `latest` tracks the upstream stable channel. |
| `installBuildx` | boolean | `true` | Install `docker-buildx-plugin`. |
| `installCompose` | boolean | `true` | Install `docker-compose-plugin` (Compose v2). |
| `dockerDashComposeVersion` | string | `v2` | If `v2`, install a `/usr/local/bin/docker-compose` shim that calls `docker compose`. `none` skips. |

## Use

```jsonc
{
  "image": "ghcr.io/alindesign/devcontainer-base:latest",
  "features": {
    "ghcr.io/alindesign/features/docker-in-docker:1": {}
  },
  "overrideCommand": false
}
```

The feature declares `entrypoint`, `init: true`, `privileged: true`, and a named volume for `/var/lib/docker` (`dind-var-lib-docker-${devcontainerId}`) so layers persist across rebuilds.

## Notes

- Requires the container to run privileged. VS Code Dev Containers handles this when the feature is present.
- The `vscode` (or remote) user is added to the `docker` group so `docker ps` works without `sudo`.
- For Apple Silicon hosts, Docker Desktop's VM already provides nested virt; works out of the box.
- If you want rootless Docker instead, this feature is not it — use upstream's rootless dind feature.
