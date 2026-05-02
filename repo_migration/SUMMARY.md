# GitHub to Forgejo Migration - Summary

## Created Structure

```
/Users/H23/logicallight/Epytype/ops/repo_migration/
├── README.md              # Main documentation and migration plan
├── QUICKSTART.md         # Step-by-step quick start guide
├── .env.example          # Sample environment variables
└── scripts/
    ├── list_github_repos.sh      # List repos from GitHub
    ├── mirror_github_repo.sh     # Mirror clone a GitHub repo
    ├── migrate_to_forgejo.sh     # Push repo to Forgejo
    ├── batch_migrate.sh          # Migrate all repos in batch
    ├── verify_migration.sh      # Verify migration success
    ├── compare_repo_counts.sh   # Compare repo counts
    └── update_local_remotes.sh  # Update local git remotes
```

## Next Steps

### 1. Prepare Tokens
- [ ] Create GitHub personal access token
- [ ] Create Forgejo admin API token
- [ ] Update `.env` file with tokens

### 2. Test Migration
- [ ] Run `list_github_repos.sh` to see repos
- [ ] Test with one small repository
- [ ] Verify the repo appears on Forgejo

### 3. Full Migration
- [ ] Review `github_repos.txt` and remove any repos to skip
- [ ] Run `batch_migrate.sh github_repos.txt`
- [ ] Monitor for failures
- [ ] Run `verify_migration.sh` to confirm

### 4. Update Infrastructure
- [ ] Update local git remotes with `update_local_remotes.sh`
- [ ] Update documentation with new URLs
- [ ] Notify team members

### 5. Cleanup
- [ ] Archive GitHub repositories (don't delete yet)
- [ ] Monitor Forgejo for issues
- [ ] Update CI/CD pipelines if needed

## Important Notes

⚠️ **Backup First**: Always have backups before migration
⚠️ **Test First**: Test with a small repo before batch migration
⚠️ **Keep GitHub Active**: Don't immediately delete GitHub repos
⚠️ **Notify Team**: Communicate changes to all stakeholders

## Current Server Info

- **repo0 Server**: 195.201.226.77
- **Forgejo URL**: https://repo.epytype.org
- **SSH Access**: `ssh devops@195.201.226.77`
- **Backups**: Enabled (window: 10-14)

## Commands Quick Reference

```bash
# Source environment
cd /Users/H23/logicallight/Epytype/ops/repo_migration
source .env

# List repos
cd scripts && ./list_github_repos.sh

# Migrate one repo
./migrate_to_forgejo.sh <repo_name> <target_org>

# Batch migrate
./batch_migrate.sh github_repos.txt

# Verify
./verify_migration.sh github_repos.txt

# Update local remotes
./update_local_remotes.sh github_repos.txt
```

## References

- Forgejo API: https://repo.epytype.org/api/swagger
- GitHub API: https://docs.github.com/en/rest
- Git Mirroring: https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---mirror
