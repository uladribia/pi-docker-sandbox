# Pi Agent Sandbox

Run the [pi coding agent](https://github.com/badlogic/pi) inside a hardened Docker container with pre-installed skills. The agent can only access your current project directory.

## TL;DR

```bash
./install.sh                          # build image + install launcher
cd ~/my-project
export ANTHROPIC_API_KEY="sk-..."
pi-sandboxed                          # interactive session
pi-sandboxed "fix the failing tests"  # with prompt
```

## Prerequisites

Docker must be installed and your user must be in the `docker` group:

```bash
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
newgrp docker
```

## Installation

```bash
git clone <this-repo> ~/Repositories/ula/pi-docker-sandbox
cd ~/Repositories/ula/pi-docker-sandbox
./install.sh
```

This builds the Docker image and installs `pi-sandboxed` to `~/.local/bin/`.

## Usage

```bash
pi-sandboxed                              # interactive session
pi-sandboxed "fix the failing tests"      # with initial prompt
pi-sandboxed --dry-run "review this code" # read-only mount
pi-sandboxed --shell                      # drop into bash for debugging
pi-sandboxed --no-filter                  # skip sensitive file filtering
pi-sandboxed --rebuild                    # force rebuild the Docker image
```

| Environment variable | Purpose |
|---------------------|---------|
| `ANTHROPIC_API_KEY` | Anthropic models |
| `OPENAI_API_KEY` | OpenAI models |
| `GOOGLE_API_KEY` | Google models |
| `BRAVE_API_KEY` | Brave search skill |
| `PI_MODEL` | Override default model |
| `PI_PROVIDER` | Override default provider |

## Pre-installed skills

The sandbox comes with all dependencies pre-installed for these skills:

| Skill | What it does | Key dependency |
|-------|-------------|----------------|
| [agent-browser](docs/skills.md#agent-browser) | Browser automation (navigate, fill forms, scrape) | Playwright + Chromium |
| [brave-search](docs/skills.md#brave-search) | Web search via Brave API | Python 3.12 + uv |
| [commit](docs/skills.md#commit) | Git commits in Conventional Commits format | git |
| [create-cli](docs/skills.md#create-cli) | Design CLI tools with consistent UX | — |
| [frontend-design](docs/skills.md#frontend-design) | Design and implement frontend interfaces | — |
| [gogcli](docs/skills.md#gogcli) | Google Workspace (Gmail, Calendar, Drive, etc.) | [gogcli](https://github.com/steipete/gogcli) binary |
| [qmd-knowledge](docs/skills.md#qmd-knowledge) | Search personal knowledge base (markdown notes) | Bun + [qmd](https://github.com/tobi/qmd) |
| [write-docs](docs/skills.md#write-docs) | Write AI-scannable technical documentation | — |

## Security model

See [docs/security.md](docs/security.md) for the full threat model and mitigations.

**Summary**: filtered workspace copy, dropped capabilities, resource limits, non-root user, ephemeral container, pi-guardrails extension.

## Supply-chain security

All external dependencies are pinned. See [docs/supply-chain.md](docs/supply-chain.md).

To update all dependencies:

```bash
./update.sh            # auto-detect and update pins in Dockerfile
./update.sh --dry-run  # preview changes
pi-sandboxed --rebuild # rebuild image
```

## Customization

Edit `Dockerfile` to add tools (e.g., `rustc`, `go`), then `pi-sandboxed --rebuild`.

Edit `SENSITIVE_PATTERNS` in `pi-sandboxed` to adjust which files are excluded from the mount.

## Scripts

| Script | Purpose |
|--------|---------|
| `install.sh` | Build image + install `pi-sandboxed` to PATH |
| `build.sh` | Build the Docker image only |
| `update.sh` | Auto-detect and update pinned dependencies |
| `pi-sandboxed` | Launcher script (installed to `~/.local/bin/`) |

## Docs

| Document | Topic |
|----------|-------|
| [docs/security.md](docs/security.md) | Threat model, mitigations, remaining risks |
| [docs/supply-chain.md](docs/supply-chain.md) | Pinning strategy, update workflow |
| [docs/skills.md](docs/skills.md) | Pre-installed skill details and requirements |
