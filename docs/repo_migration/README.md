# GitHub to Forgejo Migration Plan

## Overview
This directory contains scripts and documentation for migrating repositories from GitHub to the Forgejo instance hosted on repo0.epytype.org.

**Target Forgejo Instance:** https://repo.epytype.org (repo0 server at 195.201.226.77)

---

## Pre-Migration Checklist

### 1. Verify Forgejo Installation
```bash
# Check Forgejo container is running
ssh devops@195.201.226.77 'docker ps | grep forgejo'

# Verify web access
curl -I https://repo.epytype.org
```

### 2. Create Admin API Token on Forgejo
1. Login to https://repo.epytype.org as admin
2. Go to **Settings → Applications → Manage API Tokens**
3. Create new token with scopes:
   - `repo` (full control)
   - `admin:org` (organization access)
4. Save token as `FORGEJO_ADMIN_TOKEN` in vault or `.env`

### 3. Prepare GitHub Personal Access Token (Classic)
**Important**: Since repositories are **shared with you** (not owned by you), you need a **Classic Token**:

1. Go to: https://github.com/settings/tokens/classic
2. Click **"Generate new token (classic)"**
3. Select scopes:
   - ✅ `repo` (full repository access - covers all repos you can access)
   - ✅ `read:org` (if repos are in an organization)
4. Generate and copy the token
5. Save as `GITHUB_TOKEN`

**Why Classic Token?** 
- Fine-grained tokens require selecting specific repositories, which doesn't work for repos shared with you
- Classic tokens with `repo` scope can access **all repositories you have permission to read**, including shared ones

### 4. Get List of Accessible Repositories
```bash
# Test your token can see the shared repos
export GITHUB_TOKEN="ghp_your_classic_token"
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user/repos?per_page=5 | python3 -m json.tool | grep "full_name"
```

---

## Migration Steps

### Step 1: List GitHub Repositories to Migrate
```bash
# List all repos in organization or user account
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
export GITHUB_ORG="your-org-name"  # or GITHUB_USER="username"

# Run listing script
./scripts/list_github_repos.sh
```

**Output:** `github_repos.txt` - list of repos to migrate

### Step 2: Create Forgejo Organization/User Structure
```bash
# Create organizations or users on Forgejo to match GitHub
export FORGEJO_TOKEN="your_forgejo_admin_token"
export FORGEJO_URL="https://repo.epytype.org"

./scripts/create_forgejo_orgs.sh
```

### Step 3: Migrate Each Repository
For each repository in `github_repos.txt`:

```bash
# Mirror clone from GitHub
./scripts/mirror_github_repo.sh <repo_name>

# Push to Forgejo using migration API
./scripts/migrate_to_forgejo.sh <repo_name> <target_org>
```

**Or run all at once:**
```bash
./scripts/batch_migrate.sh github_repos.txt
```

### Step 4: Verify Migration
```bash
# Check all repos migrated successfully
./scripts/verify_migration.sh github_repos.txt

# Compare repo counts
./scripts/compare_repo_counts.sh
```

### Step 5: Update CI/CD and Webhooks
```bash
# Update GitHub Actions to Forgejo Actions (if applicable)
./scripts/migrate_ci_cd.sh

# Reconfigure webhooks for new URLs
./scripts/update_webhooks.sh
```

### Step 6: Update Local Git Remotes
```bash
# Update local clone remotes
./scripts/update_local_remotes.sh github_repos.txt
```

### Step 7: Post-Migration Tasks
1. **Update documentation** with new repo URLs
2. **Notify team members** of new repository locations
3. **Update any integrations** (Slack, Jira, etc.)
4. **Archive GitHub repos** (don't delete immediately)
5. **Monitor Forgejo** for issues

---

## Rollback Plan

If migration fails:
```bash
# Restore from backups (if available)
./scripts/rollback_migration.sh

# Or simply update remotes back to GitHub
./scripts/revert_to_github.sh github_repos.txt
```

---

## Scripts Directory

All migration scripts are located in `./scripts/`:

- `list_github_repos.sh` - List repos from GitHub
- `create_forgejo_orgs.sh` - Create org structure on Forgejo
- `mirror_github_repo.sh` - Mirror clone a GitHub repo
- `migrate_to_forgejo.sh` - Push repo to Forgejo
- `batch_migrate.sh` - Migrate all repos in batch
- `verify_migration.sh` - Verify migration success
- `compare_repo_counts.sh` - Compare repo counts
- `migrate_ci_cd.sh` - Migrate CI/CD pipelines
- `update_webhooks.sh` - Update webhook URLs
- `update_local_remotes.sh` - Update local git remotes
- `rollback_migration.sh` - Rollback migration
- `revert_to_github.sh` - Revert remotes to GitHub

---

## Important Notes

⚠️ **Backup First:** Always backup repositories before migration
⚠️ **Test Migration:** Test with a small repo first
⚠️ **Notify Team:** Communicate changes to all stakeholders
⚠️ **Keep GitHub Active:** Don't immediately delete GitHub repos

---

## References

- Forgejo API Docs: https://repo.epytype.org/api/swagger
- GitHub API Docs: https://docs.github.com/en/rest
- Git Mirroring: https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---mirror
