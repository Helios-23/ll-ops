# GitHub to Forgejo Migration - FINAL PLAN

## Migration Ready!

### Repository Mapping (Naming Convention)
| GitHub Repo | Forgejo Repo (Epytype org) |
|------------|--------------------------------|
| jperry303/epytype | Epytype/epytype |
| jperry303/epytype-docstore | Epytype/docstore |
| jperry303/epytype-kernel | Epytype/kernel |
| jperry303/epytype-lang | Epytype/lang |
| jperry303/epytype-spec | Epytype/spec |

**Note**: `epytype-forgejo-dry-run` is excluded (test repo, already migrated manually to Epytype/epytype-forgejo-dry-run)

---

## Prerequisites (Verify Tokens are Set)

```bash
source /Users/H23/logicallight/epytype.org/ops/.env
echo "GitHub Token: ${GITHUB_TOKEN:+set}"
echo "Forgejo Token: ${FORGEJO_ADMIN_TOKEN:+set}"
```

---

## Run Full Migration

### Step 1: Review Repository List
```bash
cd /Users/H23/logicallight/epytype.org/ops/repo_migration/scripts
cat github_repos.txt
```

### Step 2: Execute Migration
```bash
source /Users/H23/logicallight/epytype.org/ops/.env
./batch_migrate.sh github_repos.txt
```

**What the script does:**
1. Reads each repo from `github_repos.txt`
2. Mirror clones from GitHub (preserves all branches/tags)
3. Creates repo in Epytype org with transformed name (removes `epytype-` prefix)
4. Pushes all content to Forgejo
5. Reports success/failure for each repo

---

## Expected Results

After migration, these repos will exist on Forgejo:
- https://repo.epytype.org/Epytype/epytype
- https://repo.epytype.org/Epytype/docstore
- https://repo.epytype.org/Epytype/kernel
- https://repo.epytype.org/Epytype/lang
- https://repo.epytype.org/Epytype/spec

---

## Verification

### Check All Repos Migrated
```bash
source /Users/H23/logicallight/epytype.org/ops/.env
./verify_migration.sh github_repos.txt
```

### Compare Repo Counts
```bash
./compare_repo_counts.sh
```

### Manual Verification
Visit: https://repo.epytype.org/Epytype

---

## Post-Migration Steps

### 1. Update Local Git Remotes
```bash
# Update your local clones to point to Forgejo
./update_local_remotes.sh github_repos.txt
```

### 2. Update Documentation
- Update README files with new repo URLs
- Update links in wikis, issues, etc.

### 3. Notify Team
- Share new repo URLs: `https://repo.epytype.org/Epytype/<repo>`
- Clone URLs: `git@repo.epytype.org:Epytype/<repo>.git`

### 4. Archive GitHub Repos
- Don't delete immediately
- Archive after confirming everything works:
  - https://github.com/jperry303/epytype
  - https://github.com/jperry303/epytype-docstore
  - https://github.com/jperry303/epytype-kernel
  - https://github.com/jperry303/epytype-lang
  - https://github.com/jperry303/epytype-spec

---

## Scripts Modified for This Migration

### `migrate_to_forgejo.sh`
- Transforms repo names: removes `epytype-` prefix
- Keeps `epytype` as-is
- Defaults to `Epytype` organization

### `batch_migrate.sh`
- Skips `epytype-forgejo-dry-run` automatically
- Reports progress: `[current/total]`
- 2-second delay between repos (avoid rate limiting)

### `github_repos.txt`
- Removed `epytype-forgejo-dry-run` (test repo)
- Contains 5 repos ready for migration

---

## Quick Reference

```bash
# Navigate to scripts
cd /Users/H23/logicallight/epytype.org/ops/repo_migration/scripts

# Source environment
source /Users/H23/logicallight/epytype.org/ops/.env

# Run migration (when ready)
./batch_migrate.sh github_repos.txt

# Verify
./verify_migration.sh github_repos.txt

# Update local remotes (after verification)
./update_local_remotes.sh github_repos.txt
```

---

## Summary

**Ready for Migration:**
- ✓ Tokens configured in `.env`
- ✓ 5 repos to migrate (test repo excluded)
- ✓ Naming convention: `epytype-*` → `*` (except `epytype` stays)
- ✓ All repos target `Epytype` organization on Forgejo
- ✓ Scripts ready (no execution yet)

**Run when ready:**
```bash
cd /Users/H23/logicallight/epytype.org/ops/repo_migration/scripts
source /Users/H23/logicallight/epytype.org/ops/.env
./batch_migrate.sh github_repos.txt
```
