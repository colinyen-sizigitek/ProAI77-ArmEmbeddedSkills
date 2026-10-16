#!/usr/bin/env bash
# ProAI77 Embedded Skills Installer for Linux / macOS / WSL
set -euo pipefail

TARGET="all"
SCOPE="project"
PROJECT_PATH="$(pwd)"
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --scope) SCOPE="$2"; shift 2 ;;
        --project-path) PROJECT_PATH="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --force) FORCE=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_REPO="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$SOURCE_REPO/skills"
RULES_SOURCE="$SOURCE_REPO/shared/AGENTS.proai77.md"

echo "=========================================================="
echo "ProAI77 Embedded Skills Installer"
echo "Source:  $SOURCE_REPO"
echo "Target:  $TARGET | Scope: $SCOPE"
echo "Project: $PROJECT_PATH"
if [ "$DRY_RUN" = true ]; then echo "[DRY RUN MODE - No files will be modified]"; fi
echo "=========================================================="

if [ "$SCOPE" = "project" ]; then
    DESTS=()
    if [[ "$TARGET" =~ ^(antigravity|codex|all)$ ]]; then
        DESTS+=("$PROJECT_PATH/.agents/skills")
    fi
    if [[ "$TARGET" =~ ^(claude|all)$ ]]; then
        DESTS+=("$PROJECT_PATH/.claude/skills")
    fi
    for d in "${DESTS[@]}"; do
        echo "Installing to $d..."
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$d"
            cp -r "$SKILLS_DIR"/* "$d/"
        fi
    done

    if [ -f "$RULES_SOURCE" ]; then
        TARGET_AGENTS="$PROJECT_PATH/AGENTS.md"
        echo "Updating $TARGET_AGENTS..."
        if [ "$DRY_RUN" = false ]; then
            if [ -f "$TARGET_AGENTS" ]; then
                if grep -q "<!-- proai77-skills:begin -->" "$TARGET_AGENTS"; then
                    echo "  Updating proai77-skills section in AGENTS.md"
                else
                    cat "$RULES_SOURCE" >> "$TARGET_AGENTS"
                fi
            else
                cp "$RULES_SOURCE" "$TARGET_AGENTS"
            fi
        fi
    fi
else
    echo "User scope installation..."
    USER_DEST="$HOME/.gemini/config/plugins/proai77-embedded-skills"
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$USER_DEST"
        cp "$SOURCE_REPO/plugin.json" "$USER_DEST/"
        cp "$SOURCE_REPO/README.md" "$USER_DEST/"
        cp -r "$SOURCE_REPO/rules" "$USER_DEST/"
        cp -r "$SOURCE_REPO/skills" "$USER_DEST/"
    fi
fi

echo "ProAI77 Embedded Skills installed successfully!"
