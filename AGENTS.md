# Agent Guidelines

Instructions for AI agents working on this repository.
Aligned with [Dribia's code practices](https://code.dribia.dev).

## Core Principles

1. **Clarity over cleverness** — write code a human can read in one pass. Favor explicit names, short functions, and obvious control flow.
2. **Modularity** — one file, one concern. Shared constants live in `config.sh`. Each script does one job.
3. **Test every change** — before committing, verify your work. No untested code reaches `main`.
4. **Small, focused commits** — commit after each meaningful change, not in bulk at the end.
5. **English everywhere** — all code, comments, variable names, and documentation must be in English.

## Required Skills

Use the appropriate skill for each type of work:

| Task | Skill | When |
|------|-------|------|
| Committing changes | **commit** | After every meaningful code change. Follow Conventional Commits format. |
| Writing/updating docs | **write-docs** | When creating or modifying any `.md` file. Follow its structure and naming conventions. |
| CLI changes | **create-cli** | When adding flags, changing output format, or modifying any user-facing script behavior. |

## Naming Conventions

Use explicit, descriptive names. Someone joining the project should understand the code without context.

| Element | Convention | Examples |
|---------|-----------|----------|
| Functions | Verb-based, lowercase with underscores | `check_docker`, `build_image`, `sync_back` |
| Variables | Descriptive, uppercase for constants | `MEMORY_LIMIT`, `cleanup_dir` |
| Files | Lowercase, hyphens for multi-word | `pi-sandboxed`, `config.sh` |
| Docs | `{noun}.md` for reference, `{verb}-{noun}.md` for how-to | `security.md`, `add-skill.md` |

**Avoid** ambiguous abbreviations: `prepare_filtered_workspace`, not `prep_flt_ws`.

## Code Standards

### Shell scripts

- Start with `set -e` (fail on errors).
- Source `config.sh` for shared constants — never hardcode `IMAGE_NAME` or `NETWORK_NAME`.
- Use functions to group logic. One function, one job.
- Use arrays for command arguments (not string concatenation).
- Quote all variable expansions (`"$var"`, not `$var`).
- Add a short comment above non-obvious blocks.
- Every function and script should have a comment explaining what it does.

### Dockerfile

- Group instructions into labeled sections (`# ─── Section name ───`).
- Minimize `USER` switches — batch all root work, then all user work.
- Pin every external dependency (digest, version, commit hash).
- One logical install per `RUN` — don't mix unrelated tools in one layer.

### Documentation

- Max 150 lines per `.md` file. One topic per file.
- Start with a `## TL;DR` section.
- Use tables for structured data.
- Concrete, copy-pasteable examples.

## Linting

Run [shellcheck](https://www.shellcheck.net/) on all shell scripts before committing:

```bash
shellcheck config.sh build.sh install.sh update.sh pi-sandboxed entrypoint.sh
```

Fix all warnings. If a warning must be suppressed, add a `# shellcheck disable=SCXXXX` comment with a reason.

## Testing

Every change must be verified before committing. Follow this checklist:

| What changed | Validation command |
|-------------|-------------------|
| Any `.sh` file | `bash -n <file>` (syntax check) |
| Any `.sh` file | `shellcheck <file>` (lint) |
| `Dockerfile` | `docker buildx build -t pi-agent-sandbox .` |
| `update.sh` | `./update.sh --dry-run` |
| `pi-sandboxed` | `pi-sandboxed --help` (flags parse correctly) |
| `pi-sandboxed` | `pi-sandboxed --shell` (container starts) |
| Any `.md` file | Verify all links and cross-references resolve |

## Versioning

This project uses [semantic versioning](https://semver.org/) with git tags:

- **Format**: `vX.Y.Z` (e.g., `v0.2.1`)
- **Major** (`X`): incompatible changes to `pi-sandboxed` CLI interface
- **Minor** (`Y`): new features (new skills, new flags, new scripts)
- **Patch** (`Z`): bug fixes, doc updates, dependency bumps

Tag after pushing commits:

```bash
git tag vX.Y.Z -m "vX.Y.Z: brief description"
git push origin vX.Y.Z
```

## Branch and PR Workflow

- The `main` branch is the default and should always be stable.
- Use feature branches for non-trivial changes.
- Squash and merge PRs to keep `main` history clean.
- Delete branches after merging.
- Direct pushes to `main` are acceptable only for single-commit fixes.

## Workflow

1. Read the relevant files before making changes.
2. Make the change.
3. **Lint it**:
   ```bash
   shellcheck <modified-scripts>
   ```
4. **Test it** — follow the validation table above.
5. **Commit** using the commit skill. One commit per logical change.
6. If you touched docs, verify links and cross-references.

## Repository Structure

```
├── config.sh          # Shared constants (sourced by all scripts)
├── Dockerfile         # Container image definition
├── entrypoint.sh      # Container entrypoint (config merging)
├── build.sh           # Build the Docker image
├── install.sh         # Build + install pi-sandboxed to PATH
├── update.sh          # Auto-detect and update pinned dependencies
├── pi-sandboxed       # Main launcher script (installed to ~/.local/bin/)
├── README.md          # Project overview and usage
├── AGENTS.md          # This file — agent guidelines
└── docs/
    ├── security.md    # Threat model and mitigations
    ├── supply-chain.md # Pinning strategy and update workflow
    └── skills.md      # Pre-installed skill details
```

## Adding a New Dependency

1. Add the install step to `Dockerfile` in the appropriate section.
2. Pin the version (see `docs/supply-chain.md` for pinning conventions).
3. Test with `docker buildx build -t pi-agent-sandbox .`.
4. Update `docs/skills.md` if it's a skill dependency.
5. Run `./update.sh --dry-run` to confirm auto-detection works.
6. Commit with the commit skill.

## Things to Avoid

- Hardcoding values that belong in `config.sh`.
- Large commits that mix unrelated changes.
- Dead code (unused variables, unreachable branches).
- Unquoted variables in shell scripts.
- Duplicating logic across scripts — extract to a function or shared file.
- Ambiguous or abbreviated names.
- Committing without linting and testing.
- Non-English code, comments, or documentation.
