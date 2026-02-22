---
description: Supply-chain pinning strategy and how to update dependencies.
---

# Supply-Chain Security

## TL;DR

Every external dependency in the Dockerfile is pinned. Run `./update.sh` to auto-detect and update all pins.

## Pinning strategy

| Dependency | Pinning method | Example |
|-----------|---------------|---------|
| Base Docker image | SHA256 digest in `FROM` | `@sha256:7c2e71...` |
| uv installer | SHA256 checksum verified at build | `UV_INSTALLER_SHA256="..."` |
| npm packages | Exact version | `pi-coding-agent@0.53.1` |
| GitHub release binaries | Version in download URL | `gogcli_0.11.0_linux_amd64.tar.gz` |
| Git repos | Commit hash | `git checkout 75d32a3...` |

## Update workflow

```bash
# Preview what would change
./update.sh --dry-run

# Apply updates to Dockerfile
./update.sh

# Review changes
git diff Dockerfile

# Rebuild the image
pi-sandboxed --rebuild

# Commit
git add Dockerfile && git commit -m 'chore: update pinned dependencies'
```

## How update.sh works

The script auto-detects pinned dependencies by scanning the Dockerfile for these patterns:

| Pattern | Lookup method |
|---------|--------------|
| `FROM image@sha256:<digest>` | `docker pull` + `docker inspect` |
| `package@X.Y.Z` | `npm view <package> version` |
| `github.com/<owner>/<repo>/releases/download/vX.Y.Z` | GitHub Releases API |
| `git checkout <40-char-sha>` | `git ls-remote <url> HEAD` |
| `UV_INSTALLER_SHA256="<hash>"` | Re-download + `sha256sum` |

Adding a new pinned dependency to the Dockerfile automatically makes it discoverable — no script changes needed.
