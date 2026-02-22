#!/bin/bash
# Build the pi-agent-sandbox Docker image.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

LOG_FILE="$SCRIPT_DIR/build.log"

echo "Building $IMAGE_NAME..."
echo "Log: $LOG_FILE"

if docker buildx build -t "$IMAGE_NAME" "$SCRIPT_DIR" 2>&1 | tee "$LOG_FILE"; then
    echo "✅ Build succeeded."
else
    echo "❌ Build failed. See log: $LOG_FILE"
    exit 1
fi
