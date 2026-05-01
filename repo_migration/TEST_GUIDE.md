# Test Migration Guide

## Test Repository
- **GitHub**: `jperry303/epytype-forgejo-dry-run`
- **Target**: `https://repo.epytype.org/admin/epytype-forgejo-dry-run`

## Prerequisites
Ensure your `.env` file has the tokens:
```bash
# Check tokens are set
source /Users/H23/logicallight/epytype.org/ops/.env
echo "GitHub Token: ${GITHUB_TOKEN:0:10}..."
echo "Forgejo Token: ${FORGEJO_ADMIN_TOKEN:0:10}..."
```

## Run Test Migration

### Option 1: Use the test script (Recommended)
```bash
cd /Users/H23/logicallight/epytype.org/ops/repo_migration/scripts
source /Users/H23/logicallight/epytype.org/ops/.env

# Run the automated test
./test_migration.sh
```

### Option 2: Manual step-by-step
```bash
cd /Users/H23/logicallight/epytype.org/ops/repo_migration/scripts
source /Users/H23/logicallight/epytype.org/ops/.env

# Step 1: Mirror clone
export GITHUB_ORG="jperry303"
./mirror_github_repo.sh epytype-forgejo-dry-run

# Step 2: Create repo on Forgejo (if not exists)
curl -X POST \
  -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  "https://repo.epytype.org/api/v1/user/repos" \
  -d '{"name":"epytype-forgejo-dry-run","private":false}'

# Step 3: Push to Forgejo
cd /tmp/repo_migration/epytype-forgejo-dry-run.git
git push --mirror "https://$FORGEJO_ADMIN_TOKEN@repo.epytype.org/admin/epytype-forgejo-dry-run.git"
```

## Verify Test Migration

### Check via API
```bash
curl -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
  https://repo.epytype.org/api/v1/repos/admin/epytype-forgejo-dry-run | \
  python3 -m json.tool
```

### Check via Web
Open in browser: https://repo.epytype.org/admin/epytype-forgejo-dry-run

### Verify branches and tags
```bash
# Check branches
curl -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
  https://repo.epytype.org/api/v1/repos/admin/epytype-forgejo-dry-run/branches | \
  python3 -c "import sys, json; branches = json.load(sys.stdin); print('\n'.join([b['name'] for b in branches]))"

# Check tags
curl -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
  https://repo.epytype.org/api/v1/repos/admin/epytype-forgejo-dry-run/tags | \
  python3 -c "import sys, json; tags = json.load(sys.stdin); print('\n'.join([t['name'] for t in tags]))"
```

## Expected Results

After successful test migration:
- ✓ Repository visible at https://repo.epytype.org/admin/epytype-forgejo-dry-run
- ✓ All branches migrated
- ✓ All tags migrated
- ✓ Commit history preserved
- ✓ Same file structure as GitHub

## If Test Succeeds

Once test migration is successful, you can proceed with full migration:

```bash
# List all repos
./list_github_repos.sh

# Review the list
cat github_repos.txt

# Remove test repo from list if desired
# vim github_repos.txt

# Run full migration
./batch_migrate.sh github_repos.txt
```

## Troubleshooting

### Authentication Error
```bash
# Verify GitHub token works
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user/repos?per_page=1

# Verify Forgejo token works
curl -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
  https://repo.epytype.org/api/v1/user/repos?limit=1
```

### Push Fails
```bash
# Check if repo exists on Forgejo
curl -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
  https://repo.epytype.org/api/v1/repos/admin/epytype-forgejo-dry-run

# If 404, create it first (see Step 2 above)
```

### Mirror Clone Fails
```bash
# Check GitHub token has access
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/jperry303/epytype-forgejo-dry-run

# Should return 200, not 404 or 403
```
