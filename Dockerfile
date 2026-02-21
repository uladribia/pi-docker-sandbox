# Pin base image by digest to prevent supply-chain attacks.
# Using Node 22 (required by @aliou/sh dependency of pi-guardrails).
# To update: docker pull mcr.microsoft.com/devcontainers/typescript-node:1-22-bookworm
#            docker inspect --format='{{index .RepoDigests 0}}' mcr.microsoft.com/devcontainers/typescript-node:1-22-bookworm
FROM mcr.microsoft.com/devcontainers/typescript-node@sha256:7c2e711a4f7b02f32d2da16192d5e05aa7c95279be4ce889cff5df316f251c1d

# Avoid warnings by switching to non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# Install additional OS packages
RUN apt-get update && apt-get install -y \
    ripgrep \
    fd-find \
    zip \
    unzip \
    iptables \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

# Install uv (The Python package manager)
# Pin uv installer by checksum. To update:
#   curl -fsSL https://astral.sh/uv/install.sh | sha256sum
ENV UV_INSTALL_DIR="/usr/local/bin"
ENV UV_INSTALLER_SHA256="169fd7c68bdd40f80ab25635b1e10adfc8cef58b4935017e8560c87639d4544c"
RUN curl -fsSL https://astral.sh/uv/install.sh -o /tmp/install-uv.sh && \
    echo "${UV_INSTALLER_SHA256}  /tmp/install-uv.sh" | sha256sum -c - && \
    chmod 755 /tmp/install-uv.sh && \
    /tmp/install-uv.sh && \
    rm /tmp/install-uv.sh

# Switch to the non-root 'node' user provided by the base image
USER node

# Add uv python path to PATH to suppress "not on your PATH" warning
ENV PATH="/home/node/.local/bin:${PATH}"

# Install Python 3.12 using uv
RUN uv python install 3.12

# Install pi-coding-agent globally (pinned version)
RUN npm install -g @mariozechner/pi-coding-agent@0.53.1 2>&1 | grep -v 'npm notice'

# Suppress git detached HEAD advice
RUN git config --global advice.detachedHead false

# Install pi packages (extensions and skills)
# These match the host's ~/.pi/agent/settings.json packages list.
# WORKDIR must be somewhere writable for pi to create project-level .pi/
WORKDIR /home/node
RUN pi install npm:@juanibiapina/pi-files@0.1.0
RUN pi install npm:@aliou/pi-guardrails@0.7.7

# Install michalvavra/agents skills (pinned to specific commit)
RUN pi install git:github.com/michalvavra/agents && \
    cd /home/node/.pi/agent/git/github.com/michalvavra/agents && \
    git checkout 2f8ff22acf280cd08a833b53ebf2da9d9c2c2eab

# Preinstall common skill dependencies (pinned versions)
RUN npm install -g @mariozechner/gccli@0.1.2 @mariozechner/gdcli@0.1.1 @mariozechner/gmcli@0.2.0 2>&1 | grep -v 'npm notice'

# Ensure workspace and .pi are world-writable so any --user UID can write
USER root
RUN mkdir -p /workspace && chown node:node /workspace && \
    chmod -R a+rwX /home/node/.pi

# Install entrypoint (as root so it lands in /usr/local/bin)
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER node

# Set the workspace directory
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
