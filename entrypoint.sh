#!/bin/bash
# Container entrypoint: merge host pi config into the container, then exec.
#
# The host's ~/.pi is mounted read-only at /home/node/.pi-host.
# We import auth tokens and provider/model settings, but keep the
# container's installed packages list intact.

if [ -d /home/node/.pi-host/agent ]; then
    # Import auth tokens
    if [ -f /home/node/.pi-host/agent/auth.json ]; then
        cp /home/node/.pi-host/agent/auth.json /home/node/.pi/agent/auth.json
    fi

    # Merge settings: host overrides container, except for packages
    if [ -f /home/node/.pi-host/agent/settings.json ] && [ -f /home/node/.pi/agent/settings.json ]; then
        node -e "
            const fs = require('fs');
            const host = JSON.parse(fs.readFileSync('/home/node/.pi-host/agent/settings.json', 'utf8'));
            const container = JSON.parse(fs.readFileSync('/home/node/.pi/agent/settings.json', 'utf8'));
            const merged = { ...container, ...host, packages: container.packages };
            fs.writeFileSync('/home/node/.pi/agent/settings.json', JSON.stringify(merged, null, 2) + '\n');
        " 2>/dev/null || true
    fi
fi

exec "$@"
