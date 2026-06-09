#!/bin/bash
# Mirror clone a GitHub repository

set -e

REPO_NAME="$1"
GITHUB_TOKEN="${GITHUB_TOKEN:-$GITHUB_API_TOKEN}"
GITHUB_ORG="${GITHUB_ORG:-}"
CLONE_DIR="${CLONE_DIR:-/tmp/repo_migration}"

if [ -z "$REPO_NAME" ]; then
    echo "Usage: $0 <repo_name> [org_name]"
    exit 1
fi

mkdir -p "$CLONE_DIR"
cd "$CLONE_DIR"

# Build clone URL
if [ -n "$GITHUB_ORG" ]; then
    CLONE_URL="https://$GITHUB_TOKEN@github.com/${GITHUB_ORG}/${REPO_NAME}.git"
else
    CLONE_URL="https://$GITHUB_TOKEN@github.com/${REPO_NAME}.git"
fi

echo "Mirroring repository: $REPO_NAME"

# Mirror clone (copies all refs, tags, branches)
if [ -d "$REPO_NAME.git" ]; then
    echo "Updating existing mirror..."
    cd "$REPO_NAME.git"
    git remote update
else
    echo "Cloning mirror..."
    git clone --mirror "$CLONE_URL" "$REPO_NAME.git"
    cd "$REPO_NAME.git"
fi

echo "Mirror saved to: $CLONE_DIR/$REPO_NAME.git"
echo "Branches:"
git branch -a
echo "Tags:"
git tag -l
