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
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install pi-coding-agent
RUN npm install -g @mariozechner/pi-coding-agent

# Create non-root user
RUN groupadd -r piuser && useradd -r -g piuser -G audio,video -m -s /bin/bash piuser

# Set workspace
WORKDIR /workspace
RUN chown piuser:piuser /workspace

USER piuser

# Default entrypoint
ENTRYPOINT ["pi"]
