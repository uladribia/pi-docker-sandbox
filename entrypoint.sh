#!/bin/bash
# Import host pi config if mounted at /home/node/.pi-host
if [ -d /home/node/.pi-host/agent ]; then
    # Copy auth tokens directly
    if [ -f /home/node/.pi-host/agent/auth.json ]; then
        cp /home/node/.pi-host/agent/auth.json /home/node/.pi/agent/auth.json
    fi

    # Merge host settings into container settings:
    # Import provider/model preferences but keep the container's packages list.
    if [ -f /home/node/.pi-host/agent/settings.json ] && [ -f /home/node/.pi/agent/settings.json ]; then
        HOST_SETTINGS=/home/node/.pi-host/agent/settings.json
        CONTAINER_SETTINGS=/home/node/.pi/agent/settings.json
        node -e "
            const host = JSON.parse(require('fs').readFileSync('$HOST_SETTINGS', 'utf8'));
            const container = JSON.parse(require('fs').readFileSync('$CONTAINER_SETTINGS', 'utf8'));
            const merged = { ...container, ...host, packages: container.packages };
            require('fs').writeFileSync('$CONTAINER_SETTINGS', JSON.stringify(merged, null, 2) + '\n');
        " 2>/dev/null || true
    fi
fi

exec "$@"
