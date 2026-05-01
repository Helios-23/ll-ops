#!/bin/bash
# Compare repository counts between GitHub and Forgejo

set -e

GITHUB_TOKEN="${GITHUB_TOKEN:-$GITHUB_API_TOKEN}"
FORGEJO_TOKEN="${FORGEJO_TOKEN:-$FORGEJO_ADMIN_TOKEN}"
GITHUB_ORG="${GITHUB_ORG:-}"
FORGEJO_URL="${FORGEJO_URL:-https://repo.epytype.org}"
TARGET_ORG="${TARGET_ORG:-}"

echo "Comparing repository counts..."
echo ""

# Count GitHub repos
if [ -n "$GITHUB_ORG" ]; then
    GITHUB_COUNT=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/orgs/${GITHUB_ORG}/repos?per_page=1" \
        -I | grep -i "x-total-count" | cut -d' ' -f2 | tr -d '\r')
    echo "GitHub organization '$GITHUB_ORG': $GITHUB_COUNT repos"
else
    echo "GitHub user repos: (specify GITHUB_ORG or GITHUB_USER)"
fi

# Count Forgejo repos
if [ -n "$TARGET_ORG" ]; then
    FORGEJO_COUNT=$(curl -s -H "Authorization: token $FORGEJO_TOKEN" \
        "${FORGEJO_URL}/api/v1/orgs/${TARGET_ORG}/repos?limit=1" \
        -I | grep -i "x-total-count" | cut -d' ' -f2 | tr -d '\r')
    echo "Forgejo organization '$TARGET_ORG': $FORGEJO_COUNT repos"
else
    FORGEJO_COUNT=$(curl -s -H "Authorization: token $FORGEJO_TOKEN" \
        "${FORGEJO_URL}/api/v1/user/repos?limit=1" \
        -I | grep -i "x-total-count" | cut -d' ' -f2 | tr -d '\r')
    echo "Forgejo user repos: $FORGEJO_COUNT repos"
fi

echo ""
if [ -n "$GITHUB_COUNT" ] && [ -n "$FORGEJO_COUNT" ]; then
    if [ "$GITHUB_COUNT" = "$FORGEJO_COUNT" ]; then
        echo "✓ Repository counts match!"
    else
        DIFF=$((GITHUB_COUNT - FORGEJO_COUNT))
        echo "⚠ Repository count mismatch: GitHub has $DIFF more repos"
    fi
fi
