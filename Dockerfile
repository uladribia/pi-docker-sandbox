FROM node:20-slim

# Install common development tools
RUN apt-get update && apt-get install -y \
    git \
    bash \
    curl \
    wget \
    vim \
    nano \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    ripgrep \
    fd-find \
    jq \
    tree \
    zip \
    unzip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install pi-coding-agent
RUN npm install -g @mariozechner/pi-coding-agent

# Create non-root user with sudo access
RUN groupadd -r piuser && useradd -r -g piuser -G audio,video,sudo -m -s /bin/bash piuser
RUN echo "piuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set workspace
WORKDIR /workspace
RUN chown piuser:piuser /workspace

USER piuser

# Default entrypoint
ENTRYPOINT ["pi"]
