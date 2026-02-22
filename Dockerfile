# Pin base image by digest to prevent supply-chain attacks.
# To update: docker pull mcr.microsoft.com/devcontainers/typescript-node:1-22-bookworm
#            docker inspect --format='{{index .RepoDigests 0}}' mcr.microsoft.com/devcontainers/typescript-node:1-22-bookworm
FROM mcr.microsoft.com/devcontainers/typescript-node@sha256:7c2e711a4f7b02f32d2da16192d5e05aa7c95279be4ce889cff5df316f251c1d

ENV DEBIAN_FRONTEND=noninteractive

# ─── Root-level system installs ───────────────────────────────────────────────

# OS packages
RUN apt-get update && apt-get install -y \
    ripgrep \
    fd-find \
    zip \
    unzip \
    iptables \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

# gogcli — Google Workspace CLI (for gogcli skill)
RUN curl -fsSL https://github.com/steipete/gogcli/releases/download/v0.11.0/gogcli_0.11.0_linux_amd64.tar.gz \
    | tar -xz -C /usr/local/bin gog && \
    chmod +x /usr/local/bin/gog

# Bun runtime (for qmd-knowledge skill)
ENV BUN_INSTALL="/usr/local"
RUN curl -fsSL https://bun.sh/install | bash

# uv — Python package manager (checksum-pinned)
# To update checksum: curl -fsSL https://astral.sh/uv/install.sh | sha256sum
ENV UV_INSTALL_DIR="/usr/local/bin"
ENV UV_INSTALLER_SHA256="169fd7c68bdd40f80ab25635b1e10adfc8cef58b4935017e8560c87639d4544c"
RUN curl -fsSL https://astral.sh/uv/install.sh -o /tmp/install-uv.sh && \
    echo "${UV_INSTALLER_SHA256}  /tmp/install-uv.sh" | sha256sum -c - && \
    chmod 755 /tmp/install-uv.sh && \
    /tmp/install-uv.sh && \
    rm /tmp/install-uv.sh

# Entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Workspace directory
RUN mkdir -p /workspace && chown node:node /workspace

# ─── User-level installs (as node) ───────────────────────────────────────────

USER node
ENV PATH="/home/node/.local/bin:${PATH}"

# Python 3.12
RUN uv python install 3.12

# Git config
RUN git config --global advice.detachedHead false

# pi coding agent
RUN npm install -g @mariozechner/pi-coding-agent@0.53.1 2>&1 | grep -v 'npm notice'

# pi-skills (pinned commit)
RUN mkdir -p /home/node/.pi/agent/skills && \
    git clone https://github.com/badlogic/pi-skills /home/node/.pi/agent/skills/pi-skills && \
    cd /home/node/.pi/agent/skills/pi-skills && \
    git checkout 75d32a382b0c8aafce356d68e17d2dc94c0c953b

# pi-skills npm dependencies
RUN npm install -g @mariozechner/gccli@0.1.2 @mariozechner/gdcli@0.1.1 @mariozechner/gmcli@0.2.0 2>&1 | grep -v 'npm notice' && \
    cd /home/node/.pi/agent/skills/pi-skills/brave-search && npm install && \
    cd /home/node/.pi/agent/skills/pi-skills/browser-tools && npm install && npm audit fix --force 2>/dev/null || true && \
    cd /home/node/.pi/agent/skills/pi-skills/youtube-transcript && npm install

# agent-browser CLI (for agent-browser skill)
RUN npm install -g agent-browser@0.13.0 2>&1 | grep -v 'npm notice'

# qmd — Quick Markdown Search (for qmd-knowledge skill)
RUN bun install -g https://github.com/tobi/qmd

# pi extensions
WORKDIR /home/node
RUN pi install npm:@aliou/pi-guardrails@0.7.6 && \
    pi install git:github.com/michalvavra/agents

# ─── Final root setup ────────────────────────────────────────────────────────

USER root

# Playwright system deps + Chromium (for agent-browser skill, needs apt)
RUN npx playwright install --with-deps chromium 2>&1 | tail -10

# Make .pi writable for any --user UID
RUN chmod -R a+rwX /home/node/.pi

# ─── Runtime ──────────────────────────────────────────────────────────────────

USER node
WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
