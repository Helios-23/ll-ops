#!/bin/bash
# Update local git remotes from GitHub to Forgejo

set -e

REPO_LIST="${1:-github_repos.txt}"
FORGEJO_URL="${FORGEJO_URL:-git@repo.epytype.org}"
TARGET_ORG="${TARGET_ORG:-}"
BACKUP_REMOTE="${BACKUP_REMOTE:-github-backup}"

if [ ! -f "$REPO_LIST" ]; then
    echo "Error: Repo list file not found: $REPO_LIST"
    exit 1
fi

echo "Updating local git remotes..."
echo "New remote URL: $FORGEJO_URL"
echo ""

while IFS= read -r REPO_FULL; do
    REPO_NAME=$(basename "$REPO_FULL")
    LOCAL_PATH="${REPO_NAME}"
    
    if [ ! -d "$LOCAL_PATH/.git" ]; then
        echo "⚠ Skipping $REPO_NAME (not a git repo)"
        continue
    fi
    
    cd "$LOCAL_PATH"
    
    # Backup current GitHub remote
    git remote rename origin "$BACKUP_REMOTE" 2>/dev/null || true
    
    # Add new Forgejo remote
    if [ -n "$TARGET_ORG" ]; then
        NEW_REMOTE="${FORGEJO_URL}:${TARGET_ORG}/${REPO_NAME}.git"
    else
        NEW_REMOTE="${FORGEJO_URL}:${REPO_NAME}.git"
    fi
    
    git remote add origin "$NEW_REMOTE" 2>/dev/null || \
        git remote set-url origin "$NEW_REMOTE"
    
    echo "✓ Updated $REPO_NAME"
    echo "  Origin: $NEW_REMOTE"
    echo "  Backup: $BACKUP_REMOTE"
    echo ""
    
    cd ..
done < "$REPO_LIST"

echo "========================================"
echo "Remote update complete!"
echo "========================================"
echo "To push all repos: git push -u origin --all"
echo "To restore GitHub: git remote rename $BACKUP_REMOTE origin"
