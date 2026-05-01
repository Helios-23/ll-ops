#!/bin/bash
# Test migration with a single repository

set -e

TEST_REPO="epytype-forgejo-dry-run"
TARGET_ORG="Epytype"
FORGEJO_URL="https://repo.epytype.org"

echo "========================================"
echo "Test Migration: $TEST_REPO -> $TARGET_ORG"
echo "========================================"
echo ""

# Step 1: Mirror clone from GitHub
echo "Step 1: Mirror cloning from GitHub..."
export GITHUB_ORG="jperry303"
./mirror_github_repo.sh "$TEST_REPO"

if [ $? -ne 0 ]; then
    echo "✗ Mirror clone failed!"
    exit 1
fi

echo "✓ Mirror clone complete"
echo ""

# Step 2: Create repo on Forgejo (if not exists)
echo "Step 2: Checking/Creating repository on Forgejo..."
echo "Target: ${FORGEJO_URL}/${TARGET_ORG}/${TEST_REPO}"
echo ""

# Check if repo already exists
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
    "${FORGEJO_URL}/api/v1/repos/${TARGET_ORG}/${TEST_REPO}")

if [ "$HTTP_CODE" = "200" ]; then
    echo "Repository already exists on Forgejo"
else
    # Create the repo under organization
    curl -s -X POST \
        -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        "${FORGEJO_URL}/api/v1/orgs/${TARGET_ORG}/repos" \
        -d "{
            \"name\": \"${TEST_REPO}\",
            \"private\": false,
            \"mirror\": false
        }" | python3 -m json.tool
    
    if [ $? -ne 0 ]; then
        echo "✗ Failed to create repository on Forgejo"
        exit 1
    fi
fi

echo "✓ Repository ready on Forgejo"
echo ""

# Step 3: Push to Forgejo
echo "Step 3: Pushing to Forgejo..."
cd /tmp/repo_migration/$TEST_REPO.git
git push --mirror "https://$FORGEJO_ADMIN_TOKEN@repo.epytype.org/${TARGET_ORG}/${TEST_REPO}.git"

if [ $? -ne 0 ]; then
    echo "✗ Push to Forgejo failed!"
    exit 1
fi

echo "✓ Push complete"
echo ""

# Step 4: Verify
echo "Step 4: Verifying migration..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
    "${FORGEJO_URL}/api/v1/repos/${TARGET_ORG}/${TEST_REPO}")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Migration successful!"
    echo ""
    echo "View at: ${FORGEJO_URL}/${TARGET_ORG}/${TEST_REPO}"
    
    # Show repo details
    curl -s -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
        "${FORGEJO_URL}/api/v1/repos/${TARGET_ORG}/${TEST_REPO}" | \
        python3 -c "
import sys, json
repo = json.load(sys.stdin)
print('Name:', repo['full_name'])
print('Description:', repo.get('description', 'N/A'))
print('Clone URL:', repo['clone_url'])
print('Default branch:', repo.get('default_branch', 'N/A'))
"
    
    # Show branches
    echo ""
    echo "Branches:"
    curl -s -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
        "${FORGEJO_URL}/api/v1/repos/${TARGET_ORG}/${TEST_REPO}/branches" | \
        python3 -c "import sys, json; branches = json.load(sys.stdin); [print(f'  - {b[\"name\"]}') for b in branches]"
    
    # Show tags
    echo ""
    echo "Tags:"
    curl -s -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
        "${FORGEJO_URL}/api/v1/repos/${TARGET_ORG}/${TEST_REPO}/tags" | \
        python3 -c "import sys, json; tags = json.load(sys.stdin); [print(f'  - {t[\"name\"]}') for t in tags]"
else
    echo "✗ Verification failed!"
    exit 1
fi

echo ""
echo "========================================"
echo "Test migration complete!"
echo "========================================"
