#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/build.log"

echo "Building pi-agent-sandbox..."
echo "Log: $LOG_FILE"

if docker buildx build -t pi-agent-sandbox "$SCRIPT_DIR" 2>&1 | tee "$LOG_FILE"; then
    echo "✅ Build succeeded."
else
    echo "❌ Build failed. See log: $LOG_FILE"
    exit 1
fi
