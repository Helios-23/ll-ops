#!/bin/bash
# Batch migrate all repositories from a list.

set -e

REPO_LIST="${1:-github_repos.txt}"
FORGEJO_TOKEN="${FORGEJO_TOKEN:-$FORGEJO_ADMIN_TOKEN}"
GITHUB_TOKEN="${GITHUB_TOKEN:-$GITHUB_API_TOKEN}"
TARGET_ORG="${2:-Epytype}"

if [ ! -f "$REPO_LIST" ]; then
    echo "Error: Repo list file not found: $REPO_LIST"
    echo "Usage: $0 <repo_list_file> [target_org]"
    echo "Default target org: Epytype"
    exit 1
fi

echo "Starting batch migration of repositories from $REPO_LIST"
echo "Target organization: $TARGET_ORG"

TOTAL=$(wc -l < "$REPO_LIST")
CURRENT=0
SUCCESS=0
FAILED=0
FAILED_REPOS=""

while IFS= read -r REPO_FULL; do
    CURRENT=$((CURRENT + 1))
    
    # Skip test repo if present
    if echo "$REPO_FULL" | grep -q "epytype-forgejo-dry-run"; then
        echo ""
        echo "========================================"
        echo "[$CURRENT/$TOTAL] Skipping test repo: $REPO_FULL"
        echo "========================================"
        continue
    fi
    
    echo ""
    echo "========================================"
    echo "[$CURRENT/$TOTAL] Migrating: $REPO_FULL"
    echo "========================================"
    
    ./migrate_to_forgejo.sh "$REPO_FULL" "$TARGET_ORG" || true
    
    # Check if migration succeeded
    REPO_NAME=$(basename "$REPO_FULL")
    if [ "$REPO_NAME" = "epytype" ]; then
        FORGEJO_REPO="epytype"
    else
        FORGEJO_REPO=$(echo "$REPO_NAME" | sed 's/^epytype-//')
    fi
    
    # Verify repo exists on Forgejo
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $FORGEJO_TOKEN" \
        "https://repo.epytype.org/api/v1/repos/${TARGET_ORG}/${FORGEJO_REPO}")
    
    if [ "$HTTP_CODE" = "200" ]; then
        SUCCESS=$((SUCCESS + 1))
        echo "✓ Success: $REPO_NAME -> $FORGEJO_REPO"
    else
        FAILED=$((FAILED + 1))
        FAILED_REPOS="$FAILED_REPOS $REPO_NAME"
        echo "✗ Failed: $REPO_NAME"
    fi
    
    # Small delay to avoid rate limiting
    sleep 2
done < "$REPO_LIST"

echo ""
echo "========================================"
echo "Migration Complete"
echo "========================================"
echo "Total: $TOTAL (minus skipped test repos)"
echo "Success: $SUCCESS"
echo "Failed: $FAILED"

if [ -n "$FAILED_REPOS" ]; then
    echo ""
    echo "Failed repositories:"
    for REPO in $FAILED_REPOS; do
        echo "  - $REPO"
    done
    exit 1
fi
