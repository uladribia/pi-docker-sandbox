---
description: How session persistence works across pi-sandboxed runs.
---

# Session Persistence

## TL;DR

Conversation history survives container restarts automatically when you launch
`pi-sandboxed` from the same directory. Use `--new-session` to start fresh.

## How It Works

pi stores sessions at `~/.pi/agent/sessions/<encoded-path>/` where the path
is the working directory at launch time, with slashes replaced by hyphens and
wrapped in `--` (e.g. `/home/user/my-project` → `--home-user-my-project--`).

Inside the container `pwd` is always `/workspace`, so the container's session
key is `--workspace--`. `pi-sandboxed` mounts the host's project-scoped
session directory to that container path:

```
~/.pi/agent/sessions/<host-encoded-pwd>/  →  /home/node/.pi/agent/sessions/--workspace--/
```

This means:

| Scenario | Result |
|----------|--------|
| Same directory, second run | Conversation continues |
| Different directory | Independent session |
| Native pi + pi-sandboxed in same dir | Shared session history |
| `--new-session` flag | Ephemeral session, nothing written to disk |
| `--shell` mode | Always ephemeral (no pi session to persist) |

## Session Storage Location

```
~/.pi/agent/sessions/
└── --home-user-my-project--/   ← one dir per project path
    ├── session-<id>.json
    └── ...
```

## Flags

| Flag | Behavior |
|------|----------|
| *(default)* | Load and save session for current directory |
| `--new-session` | Skip mount; container session is ephemeral |

## Examples

```bash
# Continue the previous session for this project
cd ~/my-project && pi-sandboxed

# Start a brand-new session
pi-sandboxed --new-session "let's approach this differently"

# List sessions for a project
ls ~/.pi/agent/sessions/--home-user-my-project--/
```
