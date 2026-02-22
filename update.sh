#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

DOCKERFILE="$SCRIPT_DIR/Dockerfile"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --help|-h)
            echo "Usage: ./update.sh [--dry-run]"
            echo ""
            echo "Auto-detects pinned dependencies in the Dockerfile and updates them."
            echo "Supports: Docker image digests, npm packages, GitHub releases, git commits, uv checksum."
            echo ""
            echo "Options:"
            echo "  --dry-run   Show what would change without modifying the Dockerfile"
            exit 0
            ;;
    esac
done

echo "=== Pi Sandbox Dependency Updater ==="
echo ""

CHANGES=()

apply() {
    local label="$1" old="$2" new="$3"
    if [ "$old" = "$new" ] || [ -z "$new" ]; then
        echo "   ✅ Up to date (${old:0:40})"
        return
    fi
    CHANGES+=("$label: $old -> $new")
    if [ "$DRY_RUN" = false ]; then
        sed -i "s|${old}|${new}|g" "$DOCKERFILE"
    fi
}

# ---------------------------------------------------------------------------
# 1. Docker base image digests
#    Matches: FROM <image>@sha256:<digest>
#    Requires the "To update: docker pull <tag>" comment convention above it.
# ---------------------------------------------------------------------------
echo "── Docker base images ──"
while IFS= read -r tag; do
    echo "🔍 $tag"
    old_digest=$(grep -oP 'sha256:\K[a-f0-9]{64}' "$DOCKERFILE" | head -1)
    if docker pull "$tag" > /dev/null 2>&1; then
        new_digest=$(docker inspect --format='{{index .RepoDigests 0}}' "$tag" | grep -oP 'sha256:\K[a-f0-9]+')
        apply "$tag digest" "$old_digest" "$new_digest"
    else
        echo "   ⚠️  Could not pull image (docker not available?)"
    fi
done < <(grep -oP 'docker pull \K\S+' "$DOCKERFILE")
echo ""

# ---------------------------------------------------------------------------
# 2. npm packages (npm install -g, pi install npm:)
#    Matches: <package>@<semver>
# ---------------------------------------------------------------------------
echo "── npm packages ──"
while IFS= read -r entry; do
    # Split on last @ to handle scoped packages like @scope/pkg@1.0.0
    ver="${entry##*@}"
    pkg="${entry%@$ver}"
    [ -z "$pkg" ] && continue
    echo "🔍 $pkg@$ver"
    new_ver=$(npm view "$pkg" version 2>/dev/null || true)
    apply "$pkg" "$ver" "$new_ver"
done < <(grep -oP '[\w@/.-]+@[0-9]+\.[0-9]+\.[0-9]+' "$DOCKERFILE" | grep -v sha256 | grep -v UV_INSTALLER | sort -u)
echo ""

# ---------------------------------------------------------------------------
# 3. GitHub release downloads
#    Matches: github.com/<owner>/<repo>/releases/download/v<version>/
# ---------------------------------------------------------------------------
echo "── GitHub releases ──"
while IFS= read -r match; do
    owner_repo=$(echo "$match" | grep -oP 'github\.com/\K[^/]+/[^/]+')
    old_ver=$(echo "$match" | grep -oP 'download/v\K[0-9]+\.[0-9]+\.[0-9]+')
    echo "🔍 $owner_repo@$old_ver"
    new_ver=$(curl -fsSL "https://api.github.com/repos/$owner_repo/releases/latest" 2>/dev/null \
        | grep -oP '"tag_name":\s*"v\K[0-9]+\.[0-9]+\.[0-9]+' || true)
    if [ -n "$new_ver" ] && [ "$old_ver" != "$new_ver" ]; then
        # Replace all occurrences of the versioned filename and download path
        CHANGES+=("$owner_repo: $old_ver -> $new_ver")
        if [ "$DRY_RUN" = false ]; then
            repo_name=$(basename "$owner_repo")
            sed -i "s|${repo_name}/releases/download/v${old_ver}|${repo_name}/releases/download/v${new_ver}|g" "$DOCKERFILE"
            sed -i "s|${repo_name}_${old_ver}|${repo_name}_${new_ver}|g" "$DOCKERFILE"
        fi
    else
        echo "   ✅ Up to date ($old_ver)"
    fi
done < <(grep -oP 'github\.com/[^/]+/[^/]+/releases/download/v[0-9]+\.[0-9]+\.[0-9]+' "$DOCKERFILE" | sort -u)
echo ""

# ---------------------------------------------------------------------------
# 4. Git commit pins
#    Matches: git clone <url> ... && git checkout <sha>
# ---------------------------------------------------------------------------
echo "── Git commit pins ──"
while IFS= read -r sha; do
    # Find the clone URL on the same RUN block (search backwards from the checkout line)
    line_num=$(grep -n "$sha" "$DOCKERFILE" | head -1 | cut -d: -f1)
    url=$(head -n "$line_num" "$DOCKERFILE" | grep -oP 'git clone \Khttps?://\S+' | tail -1)
    echo "🔍 $url (${sha:0:12})"
    new_sha=$(git ls-remote "$url" HEAD 2>/dev/null | awk '{print $1}')
    apply "$(basename "$url")" "$sha" "$new_sha"
done < <(grep -oP 'git checkout \K[a-f0-9]{40}' "$DOCKERFILE")
echo ""

# ---------------------------------------------------------------------------
# 5. uv installer checksum
#    Matches: UV_INSTALLER_SHA256="<sha256>"
# ---------------------------------------------------------------------------
echo "── Checksums ──"
old_uv_sha=$(grep -oP 'UV_INSTALLER_SHA256="\K[a-f0-9]{64}' "$DOCKERFILE" || true)
if [ -n "$old_uv_sha" ]; then
    echo "🔍 uv installer checksum"
    new_uv_sha=$(curl -fsSL https://astral.sh/uv/install.sh 2>/dev/null | sha256sum | awk '{print $1}')
    apply "uv installer" "$old_uv_sha" "$new_uv_sha"
fi
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ ${#CHANGES[@]} -eq 0 ]; then
    echo "✅ All dependencies are up to date."
else
    echo "📦 ${#CHANGES[@]} update(s) found:"
    for change in "${CHANGES[@]}"; do
        echo "   • $change"
    done
    echo ""
    if [ "$DRY_RUN" = true ]; then
        echo "🔒 Dry run — no changes were made."
        echo "   Run without --dry-run to apply."
    else
        echo "✅ Dockerfile updated."
        echo ""
        echo "Next steps:"
        echo "  1. Review:  git diff Dockerfile"
        echo "  2. Rebuild: ./install.sh  (or: pi-sandboxed --rebuild)"
        echo "  3. Commit:  git add Dockerfile && git commit -m 'chore: update pinned dependencies'"
    fi
fi
