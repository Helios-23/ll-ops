#!/bin/bash
# Batch migrate all repositories from a list

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
    
    ./migrate_to_forgejo.sh "$REPO_FULL" "$TARGET_ORG"
    
    if [ $? -eq 0 ]; then
        SUCCESS=$((SUCCESS + 1))
        echo "✓ Success: $REPO_FULL"
    else
        FAILED=$((FAILED + 1))
        FAILED_REPOS="$FAILED_REPOS $REPO_FULL"
        echo "✗ Failed: $REPO_FULL"
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

echo "Starting batch migration of repositories from $REPO_LIST"
echo "Target organization: ${TARGET_ORG:-<none, repos will be under admin>}"

TOTAL=$(wc -l < "$REPO_LIST")
CURRENT=0
SUCCESS=0
FAILED=0
FAILED_REPOS=""

while IFS= read -r REPO_FULL; do
    CURRENT=$((CURRENT + 1))
    # Extract repo name from org/repo format
    REPO_NAME=$(basename "$REPO_FULL")
    
    echo ""
    echo "========================================"
    echo "[$CURRENT/$TOTAL] Migrating: $REPO_NAME"
    echo "========================================"
    
    if [ -n "$TARGET_ORG" ]; then
        ./migrate_to_forgejo.sh "$REPO_NAME" "$TARGET_ORG"
    else
        ./migrate_to_forgejo.sh "$REPO_NAME"
    fi
    
    if [ $? -eq 0 ]; then
        SUCCESS=$((SUCCESS + 1))
        echo "✓ Success: $REPO_NAME"
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
echo "Total: $TOTAL"
echo "Success: $SUCCESS"
echo "Failed: $FAILED"

if [ -n "$FAILED_REPOS" ]; then
    echo ""
    echo "Failed repositories:"
    for REPO in $FAILED_REPOS; do
        echo "  - $REPO"
    done
fi
