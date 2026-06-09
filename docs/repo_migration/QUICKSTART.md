# Quick Start Guide - GitHub to Forgejo Migration

## Prerequisites

1. **Forgejo Admin Token**
   - Login to https://repo.epytype.org
   - Settings → Applications → Manage API Tokens
   - Create token with `repo` and `admin:org` scopes
   - Save as `FORGEJO_ADMIN_TOKEN`

2. **GitHub Token for Shared Repositories**
   - **Important**: Since repos are shared with you (not owned by you), use a **Classic Personal Access Token** (not fine-grained):
   - GitHub Settings → Developer settings → Personal access tokens → **Tokens (classic)**
   - Generate new token with scopes:
     - `repo` (full repository access - covers repos shared with you)
     - `read:org` (if repos are in an organization)
   - Save as `GITHUB_TOKEN`
   
   **Why Classic Token?** Fine-grained tokens require selecting specific repos, which doesn't work for repos shared with you. Classic tokens with `repo` scope can access all repos you have permission to read.

3. **Update .env file**
   ```bash
   # Add to /Users/H23/logicallight/Epytype/ops/.env or docs/repo_migration/.env
   export FORGEJO_ADMIN_TOKEN="your_forgejo_token_here"
   export GITHUB_TOKEN="ghp_your_classic_github_token_here"
   export GITHUB_ORG="org-name-if-applicable"  # if repos are in an org
   export TARGET_ORG="your_forgejo_org"  # optional
   ```

## Step-by-Step Execution

### 1. List GitHub Repositories
```bash
cd /Users/H23/logicallight/Epytype/ops/docs/repo_migration/scripts
source /Users/H23/logicallight/Epytype/ops/.env

# List all repos
./list_github_repos.sh
# Output: github_repos.txt
```

### 2. Review and Edit Repo List (Optional)
```bash
# Edit the list to exclude certain repos
vim github_repos.txt
```

### 3. Create Forgejo Organization (If Needed)
```bash
# Create org structure on Forgejo to match GitHub
./create_forgejo_orgs.sh
```

### 4. Run Batch Migration
```bash
# Migrate all repos (this will take time)
./batch_migrate.sh github_repos.txt

# Or migrate one at a time for testing
./migrate_to_forgejo.sh <repo_name> <target_org>
```

### 5. Verify Migration
```bash
# Check all repos migrated
./verify_migration.sh github_repos.txt

# Compare counts
./compare_repo_counts.sh
```

### 6. Update Local Remotes
```bash
# After verifying migration, update your local clones
./update_local_remotes.sh github_repos.txt
```

## Testing First

Before migrating all repos, test with a single small repo:

```bash
# Test with a single repo
export REPO_NAME="test-repo"
./mirror_github_repo.sh $REPO_NAME
./migrate_to_forgejo.sh $REPO_NAME "target-org"

# Verify
curl -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
  https://repo.epytype.org/api/v1/repos/target-org/$REPO_NAME
```

## Common Issues

### Authentication Errors
- Verify tokens have correct scopes
- Check token expiration dates
- Test tokens manually with curl

### Rate Limiting
- GitHub: 5000 requests/hour for authenticated requests
- Add delays between migrations: edit `batch_migrate.sh` and increase `sleep` value

### Mirror Clone Fails
- Check repo permissions (private vs public)
- Verify GitHub token has access to the repo
- Try cloning manually first

## Post-Migration

1. **Update Documentation**
   - Update README files with new repo URLs
   - Update links in wikis, issues, etc.

2. **Notify Team**
   - Send communication about new repo locations
   - Provide new clone URLs

3. **Archive GitHub Repos**
   - Don't delete immediately
   - Archive after confirming everything works

4. **Monitor Forgejo**
   - Check logs: `ssh devops@repo0 'docker logs forgejo'`
   - Monitor disk space: `ssh devops@repo0 'df -h'`

## Rollback

If something goes wrong:

```bash
# Revert local remotes to GitHub
./revert_to_github.sh github_repos.txt

# Or manually:
git remote set-url origin <github_url>
```
