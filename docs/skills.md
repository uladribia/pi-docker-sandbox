---
description: Pre-installed skills in the sandbox and their dependencies.
---

# Pre-installed Skills

## TL;DR

All skill dependencies are baked into the Docker image. No runtime installation needed.

## agent-browser

Browser automation CLI for navigating pages, filling forms, clicking buttons, taking screenshots, and scraping data.

| Dependency | Version | Installed via |
|-----------|---------|---------------|
| `agent-browser` | 0.13.0 | `npm install -g` |
| Playwright + Chromium | (bundled) | `npx playwright install --with-deps chromium` |

Requires no API key. Runs headless Chromium inside the container.

## brave-search

Web search via the Brave Search API.

| Dependency | Version | Installed via |
|-----------|---------|---------------|
| Python | 3.12 | `uv python install` |
| uv | latest | Installer script |

Requires `BRAVE_API_KEY` (or `BRAVE_SEARCH_API_KEY`) environment variable.

## commit

Creates git commits using Conventional Commits format.

No additional dependencies — uses git (pre-installed in base image).

## create-cli

Guides for designing CLI tools with consistent UX patterns.

No additional dependencies — this is a documentation/guidance skill.

## frontend-design

Designs and implements frontend interfaces with strong aesthetic direction.

No additional dependencies — outputs HTML/CSS/JS code directly.

## gogcli

Google Workspace automation for Gmail, Calendar, Drive, Contacts, Tasks, and Sheets.

| Dependency | Version | Installed via |
|-----------|---------|---------------|
| `gog` (gogcli binary) | 0.11.0 | [GitHub release](https://github.com/steipete/gogcli) |

Requires Google OAuth credentials. Set `GOG_ACCOUNT=you@gmail.com` or use `--account` flag.

## qmd-knowledge

Search and retrieve from a personal knowledge base of indexed markdown files.

| Dependency | Version | Installed via |
|-----------|---------|---------------|
| Bun | latest | Official installer |
| qmd | latest | `bun install -g` |

Requires a pre-configured qmd index. See [qmd docs](https://github.com/tobi/qmd) for setup.

## write-docs

Guides for writing AI-scannable technical documentation.

No additional dependencies — this is a documentation/guidance skill.

## Adding a new skill

1. Add the dependency install step to `Dockerfile`.
2. Pin the version (see [supply-chain.md](supply-chain.md)).
3. Run `pi-sandboxed --rebuild`.
4. The `update.sh` script will auto-detect the new pin.
