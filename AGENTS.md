# Agent Guidelines

Instructions for AI agents working on this repository.

## Core Principles

1. **Clarity over cleverness** — write code a human can read in one pass. Favor explicit names, short functions, and obvious control flow.
2. **Modularity** — one file, one concern. Shared constants live in `config.sh`. Each script does one job.
3. **Test every change** — before committing, verify your work (syntax check with `bash -n`, dry-run scripts, `docker build` when touching the Dockerfile).
4. **Small, focused commits** — commit after each meaningful change, not in bulk at the end.

## Required Skills

Use the appropriate skill for each type of work:

| Task | Skill | When |
|------|-------|------|
| Committing changes | **commit** | After every meaningful code change. Follow Conventional Commits format. |
| Writing/updating docs | **write-docs** | When creating or modifying any `.md` file. Follow its structure and naming conventions. |
| CLI changes | **create-cli** | When adding flags, changing output format, or modifying any user-facing script behavior. |

## Code Standards

### Shell scripts

- Start with `set -e` (fail on errors).
- Source `config.sh` for shared constants — never hardcode `IMAGE_NAME` or `NETWORK_NAME`.
- Use functions to group logic. Name them as verbs: `check_docker`, `build_image`, `sync_back`.
- Use arrays for command arguments (not string concatenation).
- Quote all variable expansions (`"$var"`, not `$var`).
- Add a short comment above non-obvious blocks.

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

## Workflow

1. Read the relevant files before making changes.
2. Make the change.
3. **Test it** — at minimum, syntax-check all modified scripts:
   ```bash
   bash -n <script>.sh
   ```
   For Dockerfile changes, run a build. For `update.sh` changes, run `--dry-run`.
4. **Commit** using the commit skill. One commit per logical change.
5. If you touched docs, verify links and cross-references.

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
3. Test with `docker build`.
4. Update `docs/skills.md` if it's a skill dependency.
5. Run `./update.sh --dry-run` to confirm auto-detection works.
6. Commit with the commit skill.

## Things to Avoid

- Hardcoding values that belong in `config.sh`.
- Large commits that mix unrelated changes.
- Dead code (unused variables, unreachable branches).
- Unquoted variables in shell scripts.
- Duplicating logic across scripts — extract to a function or shared file.
- Committing without testing.
