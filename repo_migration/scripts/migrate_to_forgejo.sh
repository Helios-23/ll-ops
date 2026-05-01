#!/bin/bash
# Migrate a repository to Forgejo using the migration API

set -e

REPO_FULL="$1"
TARGET_ORG="${2:-Epytype}"
FORGEJO_URL="${FORGEJO_URL:-https://repo.epytype.org}"
FORGEJO_TOKEN="${FORGEJO_TOKEN:-$FORGEJO_ADMIN_TOKEN}"
GITHUB_TOKEN="${GITHUB_TOKEN:-$GITHUB_API_TOKEN}"
GITHUB_ORG="${GITHUB_ORG:-jperry303}"
CLONE_DIR="${CLONE_DIR:-/tmp/repo_migration}"

if [ -z "$REPO_FULL" ] || [ -z "$FORGEJO_TOKEN" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo "Usage: $0 <org/repo_name> [target_org]"
    echo "Requires: FORGEJO_TOKEN, GITHUB_TOKEN"
    echo "Default target org: Epytype"
    exit 1
fi

# Extract repo name from org/repo format
REPO_NAME=$(basename "$REPO_FULL")

# Transform repo name: remove 'epytype-' prefix if present (but keep 'epytype' as-is)
if [ "$REPO_NAME" = "epytype" ]; then
    FORGEJO_REPO_NAME="epytype"
else
    FORGEJO_REPO_NAME=$(echo "$REPO_NAME" | sed 's/^epytype-//')
fi

echo "Migrating $REPO_FULL to Forgejo..."
echo "Original name: $REPO_NAME"
echo "Forgejo name: $FORGEJO_REPO_NAME"
echo "Target organization: $TARGET_ORG"

# Mirror clone from GitHub
cd "$CLONE_DIR"
if [ -d "$REPO_NAME.git" ]; then
    echo "Using existing mirror..."
else
    echo "Cloning mirror from GitHub..."
    git clone --mirror "https://$GITHUB_TOKEN@github.com/${GITHUB_ORG}/${REPO_NAME}.git" "$REPO_NAME.git"
fi

# Create repo on Forgejo via API
echo "Creating repository on Forgejo..."
curl -s -X POST \
  -H "Authorization: token $FORGEJO_TOKEN" \
  -H "Content-Type: application/json" \
  "${FORGEJO_URL}/api/v1/orgs/${TARGET_ORG}/repos" \
  -d "{
    \"name\": \"${FORGEJO_REPO_NAME}\",
    \"private\": false,
    \"mirror\": false
  }" | python3 -m json.tool

# Push mirror to Forgejo
cd "$REPO_NAME.git"
echo "Pushing to Forgejo..."
git push --mirror "https://$FORGEJO_TOKEN@repo.epytype.org/${TARGET_ORG}/${FORGEJO_REPO_NAME}.git"

echo "Migration complete: ${FORGEJO_URL}/${TARGET_ORG}/${FORGEJO_REPO_NAME}"
