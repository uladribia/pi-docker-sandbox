# Pi Agent Sandbox

Run the [pi coding agent](https://github.com/badlogic/pi) inside a Docker container so it can only access your current project directory.

## Prerequisites

Docker must be installed and your user must be in the `docker` group:

```bash
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
newgrp docker
```

## Installation

```bash
# Clone this repo
git clone <this-repo> ~/Repositories/ula/pi-docker-sandbox

# Copy the launcher to your PATH
cp ~/Repositories/ula/pi-docker-sandbox/pi-sandboxed ~/.local/bin/
chmod +x ~/.local/bin/pi-sandboxed

# Build the image (or just run pi-sandboxed — it auto-builds on first use)
cd ~/Repositories/ula/pi-docker-sandbox && ./build.sh
```

## Usage

```bash
cd ~/my-project
export ANTHROPIC_API_KEY="sk-..."

pi-sandboxed                              # interactive session
pi-sandboxed "fix the failing tests"      # with initial prompt
pi-sandboxed --dry-run "review this code" # read-only mount
pi-sandboxed --shell                      # drop into bash for debugging
pi-sandboxed --no-filter                  # skip sensitive file filtering
pi-sandboxed --rebuild                    # force rebuild the Docker image
```

## What it does

When you run `pi-sandboxed`, it:

1. **Filters sensitive files** — copies your workspace to a temp dir, excluding `.env`, `*.pem`, `*.key`, `.npmrc`, `.git/config`, etc. The agent never sees these files.
2. **Starts a hardened container** (with [pi-guardrails](https://github.com/aliou/pi-guardrails) extension pre-installed for dangerous operation gating):
   - Volume mount of your project to `/workspace` (the only writable location)
   - Writable container filesystem (ephemeral — destroyed with `--rm`)
   - All Linux capabilities dropped (`--cap-drop=ALL`)
   - No privilege escalation (`--security-opt=no-new-privileges`)
   - Resource limits: 4GB RAM, 2 CPUs, 256 max PIDs
3. **Runs `pi`** inside the container with your API keys forwarded.
4. **Syncs changes back** to your real workspace when the session ends (excluding sensitive files).

## Security model

| Threat | Mitigation |
|---|---|
| Reads files outside project | Only `$(pwd)` is mounted |
| Deletes/corrupts your files | Filtered copy — originals untouched until sync-back |
| Reads `.env` / API keys from files | Sensitive file patterns excluded from mount |
| Exfiltrates data over network | Docker network (can add domain whitelist — see below) |
| Fork bomb / OOM | `--memory=4g --cpus=2 --pids-limit=256` |
| Privilege escalation | `--cap-drop=ALL --security-opt=no-new-privileges`, non-root user |
| Container escape | Non-root + dropped caps reduces surface; use gVisor for more |
| Persists malware in container | `--rm` deletes container on exit |

## Remaining risks

- **API key exfiltration via network**: The agent receives API keys as env vars and has outbound internet access. A prompt injection attack (e.g., from a malicious file it reads) could `curl` your keys to an external server. To mitigate, set up a proxy that injects auth headers so keys never enter the container.
- **Symlinks**: If your project contains symlinks pointing outside it, Docker will follow them. Audit your project for symlinks.
- **Sync-back overwrites**: When the session ends, changes are synced back with `rsync --delete`. If the agent deletes files in `/workspace`, they'll be deleted on your host too. Review the diff before committing.
- **Docker is not a VM**: Kernel exploits can escape containers. For higher assurance, run Docker inside a VM or use gVisor (`--runtime=runsc`).

## Network domain whitelisting (optional)

For maximum protection against data exfiltration, you can restrict outbound traffic to only API provider domains. This requires running a filtering proxy (e.g., squid) or using iptables rules. The `ALLOWED_DOMAINS` list in the `pi-sandboxed` script is a placeholder for this — a full implementation would need a sidecar proxy container.

A simpler approach: run with `--network=none` and use a local API proxy on the host that the container connects to via `--add-host`.

## Supply-chain security

All external dependencies are pinned to prevent tampering:

| Dependency | Pinning method |
|---|---|
| Base Docker image (`devcontainers/typescript-node`) | SHA256 digest in `FROM` |
| `uv` installer script | SHA256 checksum verified at build time |
| `pi-coding-agent` | Pinned npm version |
| `michalvavra/agents` (skills) | Pinned git commit hash |
| `pi-files` extension | Pinned npm version |
| `pi-guardrails` extension | Pinned npm version |
| `gccli`, `gdcli`, `gmcli` | Pinned npm versions |

To update all dependencies to their latest versions:

```bash
./update.sh            # update Dockerfile
./update.sh --dry-run  # preview changes without modifying
pi-sandboxed --rebuild # rebuild image with new versions
```

## Customization

Edit `Dockerfile` to add tools (e.g., `rustc`, `go`), then:

```bash
pi-sandboxed --rebuild
```

Edit the `SENSITIVE_PATTERNS` array in `pi-sandboxed` to adjust which files are excluded from the mount.
