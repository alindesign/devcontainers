# syntax=docker/dockerfile:1.7
#
# ghcr.io/alindesign/devcontainer-base
# ------------------------------------
# Pre-built devcontainer base with dotfiles + mise + bootstrap apt packages
# already installed. Saves ~2 minutes of feature setup on templates that
# always use these. Multi-arch (amd64 + arm64).
#
# Use as the `image` field in a devcontainer.json:
#
#   {
#     "image": "ghcr.io/alindesign/devcontainer-base:latest",
#     "features": {
#       "ghcr.io/alindesign/features/node:2": {}
#     },
#     "remoteUser": "vscode"
#   }
#
# Note: the dotfiles + mise features are already baked in here, so you do
# NOT need to add them again in the consuming devcontainer.json. Layer
# whatever languages / tools you want on top.

ARG UBUNTU_VARIANT=ubuntu
FROM mcr.microsoft.com/devcontainers/base:${UBUNTU_VARIANT}

ARG REMOTE_USER=vscode
ENV DEBIAN_FRONTEND=noninteractive

# --- dotfiles feature (inline copy) -----------------------------------------
COPY src/dotfiles /tmp/_features/dotfiles
RUN chmod +x /tmp/_features/dotfiles/install.sh \
    && _REMOTE_USER="${REMOTE_USER}" \
       SETDEFAULTSHELL=true \
       INSTALLNVIM=true \
       GITSIGNINGFORMAT=none \
       /tmp/_features/dotfiles/install.sh \
    && rm -rf /tmp/_features/dotfiles

# --- mise feature (inline copy) ---------------------------------------------
COPY src/mise /tmp/_features/mise
RUN chmod +x /tmp/_features/mise/install.sh \
    && _REMOTE_USER="${REMOTE_USER}" \
       AUTOACTIVATE=true \
       /tmp/_features/mise/install.sh \
    && rm -rf /tmp/_features/mise

LABEL org.opencontainers.image.source="https://github.com/alindesign/devcontainers"
LABEL org.opencontainers.image.description="Pre-built devcontainer base with dotfiles + mise."
LABEL org.opencontainers.image.licenses="MIT"
