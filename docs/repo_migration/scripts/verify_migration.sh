#!/bin/bash
# Verify that all repositories were migrated successfully

set -e

REPO_LIST="${1:-github_repos.txt}"
FORGEJO_URL="${FORGEJO_URL:-https://repo.epytype.org}"
FORGEJO_TOKEN="${FORGEJO_TOKEN:-$FORGEJO_ADMIN_TOKEN}"
TARGET_ORG="${TARGET_ORG:-}"

if [ ! -f "$REPO_LIST" ]; then
    echo "Error: Repo list file not found: $REPO_LIST"
    exit 1
fi

echo "Verifying migration..."
echo "Forgejo URL: $FORGEJO_URL"
echo ""

TOTAL=$(wc -l < "$REPO_LIST")
FOUND=0
MISSING=0
MISSING_REPOS=""

while IFS= read -r REPO_FULL; do
    REPO_NAME=$(basename "$REPO_FULL")
    
    if [ -n "$TARGET_ORG" ]; then
        CHECK_URL="${FORGEJO_URL}/api/v1/repos/${TARGET_ORG}/${REPO_NAME}"
    else
        # Try both org and user
        CHECK_URL="${FORGEJO_URL}/api/v1/repos/admin/${REPO_NAME}"
    fi
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $FORGEJO_TOKEN" \
        "$CHECK_URL")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✓ Found: $REPO_NAME"
        FOUND=$((FOUND + 1))
    else
        echo "✗ Missing: $REPO_NAME (HTTP $HTTP_CODE)"
        MISSING=$((MISSING + 1))
        MISSING_REPOS="$MISSING_REPOS $REPO_NAME"
    fi
done < "$REPO_LIST"

echo ""
echo "========================================"
echo "Verification Complete"
echo "========================================"
echo "Total repos in list: $TOTAL"
echo "Found on Forgejo: $FOUND"
echo "Missing: $MISSING"

if [ -n "$MISSING_REPOS" ]; then
    echo ""
    echo "Missing repositories:"
    for REPO in $MISSING_REPOS; do
        echo "  - $REPO"
    done
    exit 1
else
    echo ""
    echo "All repositories successfully migrated!"
    exit 0
fi
