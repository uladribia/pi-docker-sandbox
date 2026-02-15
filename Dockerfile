FROM mcr.microsoft.com/devcontainers/typescript-node:1-20-bookworm

# Avoid warnings by switching to non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# Install additional OS packages
# ripgrep, fd-find: Fast search tools
# python3-venv: Needed for some python tools despite uv
RUN apt-get update && apt-get install -y \
    ripgrep \
    fd-find \
    python3-venv \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install uv (The Python package manager)
# We install it to /usr/local/bin so it's available to all
ADD --chmod=755 https://astral.sh/uv/install.sh /tmp/install-uv.sh
RUN /tmp/install-uv.sh && rm /tmp/install-uv.sh

# Switch to the non-root 'node' user provided by the base image
USER node

# Install pi-coding-agent globally
# The devcontainer image configures global npm permissions correctly for the 'node' user
RUN npm install -g @mariozechner/pi-coding-agent

# Set the workspace directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
