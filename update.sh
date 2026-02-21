#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCKERFILE="$SCRIPT_DIR/Dockerfile"
BASE_IMAGE_TAG="mcr.microsoft.com/devcontainers/typescript-node:1-22-bookworm"
DRY_RUN=false

# --- Parse args ---
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --help|-h)
            echo "Usage: ./update.sh [--dry-run]"
            echo ""
            echo "Fetches the latest versions of all pinned dependencies and updates the Dockerfile."
            echo ""
            echo "Options:"
            echo "  --dry-run   Show what would change without modifying the Dockerfile"
            exit 0
            ;;
    esac
done

echo "=== Pi Sandbox Dependency Updater ==="
echo ""

# --- Helper: replace a sed-safe pattern in Dockerfile ---
update_dockerfile() {
    local pattern="$1"
    local replacement="$2"
    if [ "$DRY_RUN" = true ]; then
        return
    fi
    # Use | as delimiter since patterns may contain /
    sed -i "s|${pattern}|${replacement}|g" "$DOCKERFILE"
}

# Track changes
CHANGES=()

# --- 1. Base Docker image digest ---
echo "🔍 Checking base image: $BASE_IMAGE_TAG"
OLD_DIGEST=$(grep -oP 'sha256:[a-f0-9]+' "$DOCKERFILE" | head -1)
docker pull "$BASE_IMAGE_TAG" > /dev/null 2>&1
NEW_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$BASE_IMAGE_TAG" | grep -oP 'sha256:[a-f0-9]+')
if [ "$OLD_DIGEST" != "$NEW_DIGEST" ]; then
    CHANGES+=("Base image: $OLD_DIGEST -> $NEW_DIGEST")
    update_dockerfile "$OLD_DIGEST" "$NEW_DIGEST"
else
    echo "   ✅ Up to date ($OLD_DIGEST)"
fi

# --- 2. uv installer checksum ---
echo "🔍 Checking uv installer"
OLD_UV_SHA=$(grep 'UV_INSTALLER_SHA256=' "$DOCKERFILE" | grep -oP '[a-f0-9]{64}')
NEW_UV_SHA=$(curl -fsSL https://astral.sh/uv/install.sh 2>/dev/null | sha256sum | awk '{print $1}')
if [ "$OLD_UV_SHA" != "$NEW_UV_SHA" ]; then
    CHANGES+=("uv installer: ${OLD_UV_SHA:0:16}... -> ${NEW_UV_SHA:0:16}...")
    update_dockerfile "$OLD_UV_SHA" "$NEW_UV_SHA"
else
    echo "   ✅ Up to date (${OLD_UV_SHA:0:16}...)"
fi

# --- 3. pi-coding-agent ---
echo "🔍 Checking @mariozechner/pi-coding-agent"
OLD_PI=$(grep -oP 'pi-coding-agent@\K[0-9]+\.[0-9]+\.[0-9]+' "$DOCKERFILE")
NEW_PI=$(npm view @mariozechner/pi-coding-agent version 2>/dev/null)
if [ -n "$NEW_PI" ] && [ "$OLD_PI" != "$NEW_PI" ]; then
    CHANGES+=("pi-coding-agent: $OLD_PI -> $NEW_PI")
    update_dockerfile "pi-coding-agent@${OLD_PI}" "pi-coding-agent@${NEW_PI}"
else
    echo "   ✅ Up to date ($OLD_PI)"
fi

# --- 4. michalvavra/agents commit ---
echo "🔍 Checking michalvavra/agents"
OLD_COMMIT=$(grep -oP 'git checkout \K[a-f0-9]{40}' "$DOCKERFILE")
NEW_COMMIT=$(git ls-remote https://github.com/michalvavra/agents HEAD 2>/dev/null | awk '{print $1}')
if [ -n "$NEW_COMMIT" ] && [ "$OLD_COMMIT" != "$NEW_COMMIT" ]; then
    CHANGES+=("michalvavra/agents: ${OLD_COMMIT:0:12} -> ${NEW_COMMIT:0:12}")
    update_dockerfile "$OLD_COMMIT" "$NEW_COMMIT"
else
    echo "   ✅ Up to date (${OLD_COMMIT:0:12})"
fi

# --- 4b. pi-files ---
echo "🔍 Checking @juanibiapina/pi-files"
OLD_PF=$(grep -oP 'pi-files@\K[0-9]+\.[0-9]+\.[0-9]+' "$DOCKERFILE")
NEW_PF=$(npm view @juanibiapina/pi-files version 2>/dev/null)
if [ -n "$NEW_PF" ] && [ "$OLD_PF" != "$NEW_PF" ]; then
    CHANGES+=("pi-files: $OLD_PF -> $NEW_PF")
    update_dockerfile "pi-files@${OLD_PF}" "pi-files@${NEW_PF}"
else
    echo "   ✅ Up to date ($OLD_PF)"
fi

# --- 5. gccli / gdcli / gmcli ---
for pkg in gccli gdcli gmcli; do
    echo "🔍 Checking @mariozechner/$pkg"
    OLD_VER=$(grep -oP "${pkg}@\K[0-9]+\.[0-9]+\.[0-9]+" "$DOCKERFILE")
    NEW_VER=$(npm view "@mariozechner/$pkg" version 2>/dev/null)
    if [ -n "$NEW_VER" ] && [ "$OLD_VER" != "$NEW_VER" ]; then
        CHANGES+=("$pkg: $OLD_VER -> $NEW_VER")
        update_dockerfile "${pkg}@${OLD_VER}" "${pkg}@${NEW_VER}"
    else
        echo "   ✅ Up to date ($OLD_VER)"
    fi
done

# --- 6. pi-guardrails ---
echo "🔍 Checking @aliou/pi-guardrails"
OLD_GR=$(grep -oP 'pi-guardrails@\K[0-9]+\.[0-9]+\.[0-9]+' "$DOCKERFILE")
NEW_GR=$(npm view @aliou/pi-guardrails version 2>/dev/null)
if [ -n "$NEW_GR" ] && [ "$OLD_GR" != "$NEW_GR" ]; then
    CHANGES+=("pi-guardrails: $OLD_GR -> $NEW_GR")
    update_dockerfile "pi-guardrails@${OLD_GR}" "pi-guardrails@${NEW_GR}"
else
    echo "   ✅ Up to date ($OLD_GR)"
fi

# --- Summary ---
echo ""
if [ ${#CHANGES[@]} -eq 0 ]; then
    echo "✅ All dependencies are up to date. No changes needed."
else
    echo "📦 ${#CHANGES[@]} update(s) found:"
    for change in "${CHANGES[@]}"; do
        echo "   • $change"
    done

    if [ "$DRY_RUN" = true ]; then
        echo ""
        echo "🔒 Dry run — no changes were made."
        echo "   Run without --dry-run to apply."
    else
        echo ""
        echo "✅ Dockerfile updated."
        echo ""
        echo "Next steps:"
        echo "  1. Review:  git diff Dockerfile"
        echo "  2. Rebuild: ./install.sh  (or: pi-sandboxed --rebuild)"
        echo "  3. Commit:  git add Dockerfile && git commit -m 'Update pinned dependencies'"
    fi
fi
