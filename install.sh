#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
IMAGE_NAME="pi-agent-sandbox"

echo "=== Pi Agent Sandbox Installer ==="
echo ""

# --- Check Docker ---
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    echo ""
    echo "Install it with:"
    echo "  sudo apt-get update && sudo apt-get install -y docker.io"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Error: Cannot connect to the Docker daemon."
    echo ""
    echo "Make sure it's running and your user is in the docker group:"
    echo "  sudo systemctl start docker"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    exit 1
fi

echo "✅ Docker is available"

# --- Check rsync ---
if ! command -v rsync &> /dev/null; then
    echo "⚠  rsync not found. Sensitive file filtering will use a slower fallback."
    echo "   Install it with: sudo apt-get install -y rsync"
fi

# --- Build Docker image ---
echo ""
echo "Building Docker image '$IMAGE_NAME'..."
(cd "$SCRIPT_DIR" && docker buildx build -t "$IMAGE_NAME" .)
echo "✅ Docker image built"

# --- Install pi-sandboxed script ---
echo ""
echo "Installing pi-sandboxed to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

# Patch REPO_DIR in the script to point to the actual clone location
sed "s|REPO_DIR=.*|REPO_DIR=\"$SCRIPT_DIR\"|" "$SCRIPT_DIR/pi-sandboxed" > "$INSTALL_DIR/pi-sandboxed"
chmod +x "$INSTALL_DIR/pi-sandboxed"
echo "✅ pi-sandboxed installed"

# --- Check PATH ---
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    echo ""
    echo "⚠  $INSTALL_DIR is not in your PATH."
    echo "   Add this to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "     export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# --- Verify ---
echo ""
echo "=== Installation complete ==="
echo ""
echo "Usage:"
echo "  cd ~/your-project"
echo "  export ANTHROPIC_API_KEY=\"sk-...\""
echo "  pi-sandboxed"
echo ""
echo "Run 'pi-sandboxed --help' for all options."
