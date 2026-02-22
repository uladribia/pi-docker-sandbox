---
description: Threat model and security mitigations for the pi agent sandbox.
---

# Security Model

## TL;DR

The container runs as non-root with all capabilities dropped, resource limits enforced, and your workspace filtered to exclude secrets. It is destroyed after each session.

## How it works

When you run `pi-sandboxed`, it:

1. **Filters sensitive files** — copies your workspace to a temp dir, excluding `.env`, `*.pem`, `*.key`, `.npmrc`, `.git/config`, etc.
2. **Starts a hardened container** with [pi-guardrails](https://github.com/aliou/pi-guardrails) pre-installed for dangerous operation gating.
3. **Runs `pi`** with your API keys forwarded as env vars.
4. **Syncs changes back** when the session ends (excluding sensitive files).

## Container hardening

| Control | Setting |
|---------|---------|
| Capabilities | `--cap-drop=ALL` |
| Privilege escalation | `--security-opt=no-new-privileges` |
| Memory limit | `--memory=4g` |
| CPU limit | `--cpus=2` |
| Process limit | `--pids-limit=256` |
| User | Non-root (`node` user or host UID via `--user`) |
| Persistence | `--rm` (container destroyed on exit) |
| Filesystem | Only `/workspace` is mounted from host |

## Threat mitigations

| Threat | Mitigation |
|--------|------------|
| Reads files outside project | Only `$(pwd)` is mounted |
| Deletes/corrupts your files | Filtered copy — originals untouched until sync-back |
| Reads `.env` / API keys from files | Sensitive file patterns excluded from mount |
| Exfiltrates data over network | Docker network (add domain whitelist for more) |
| Fork bomb / OOM | Resource limits enforced |
| Privilege escalation | Capabilities dropped, no-new-privileges |
| Container escape | Non-root + dropped caps; use gVisor for more |
| Persists malware | `--rm` deletes container on exit |

## Remaining risks

- **API key exfiltration**: The agent receives API keys as env vars and has outbound internet. A prompt injection could `curl` your keys out. Mitigation: use a proxy that injects auth headers so keys never enter the container.
- **Symlinks**: Symlinks pointing outside the project will be followed by Docker. Audit your project for symlinks.
- **Sync-back overwrites**: Changes are synced back with `rsync --delete`. If the agent deletes files, they're deleted on your host too. Review diffs before committing.
- **Docker is not a VM**: Kernel exploits can escape containers. For higher assurance, run inside a VM or use gVisor (`--runtime=runsc`).

## Network whitelisting (optional)

Restrict outbound traffic to API provider domains only:

- **Simple**: Run with `--network=none` and use a local API proxy on the host via `--add-host`.
- **Advanced**: Run a filtering proxy (e.g., squid) as a sidecar container.

The `ALLOWED_DOMAINS` list in `pi-sandboxed` is a starting point for this.

## Sensitive file patterns

Default exclusions (configurable in `pi-sandboxed`):

```
.env  .env.*  .git/config  .git/credentials  .npmrc  .pypirc  *.pem  *.key  id_rsa  id_ed25519
```
