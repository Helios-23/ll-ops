# Repository Migration Summary: GitHub to Forgejo

## Migration Overview

All repositories have been successfully migrated from GitHub to Forgejo hosted on repo0.epytype.org. The migration used push-to-create functionality to automatically create repositories in the Epytype organization.

**Migration Date:** May 1-2, 2026  
**Source:** GitHub (jperry303 organization)  
**Target:** Forgejo at https://repo.epytype.org (Epytype organization)

---

## Completed Tasks

### 1. Infrastructure Preparation

- Enabled Hetzner automated backups for repo0 server via API (no server destruction)
- Fixed Terraform configuration to manage SSH keys without server replacement
- Updated SSH key lifecycle rules to prevent accidental server destruction
- Fixed Cloudflare API authentication (rolled new API token)
- Verified Cloudflare zone access for epytype.org

### 2. Forgejo Configuration

- Enabled push-to-create globally: `ENABLE_PUSH_CREATE = true`
- Enabled push-to-create for organizations: `ENABLE_PUSH_CREATE_ORG = true`
- Configured Forgejo to run behind nginx (HTTPS handled by nginx, not Forgejo)
- Created Ansible tasks for user management, organization membership, and repository access
- Added proper tags to Ansible roles: `forgejo`, `forgejo_push_create_org`, `forgejo_users`

### 3. Migration Scripts Created

Location: `/Users/H23/logicallight/Epytype/ops/repo_migration/`

**Documentation:**
- `README.md` - Main migration plan and steps
- `QUICKSTART.md` - Step-by-step quick start guide
- `FINAL_SUMMARY.md` - Final preparation summary
- `TEST_GUIDE.md` - Test migration guide
- `../SETUP_GUIDE.md` - Setup guide for checking out repositories

**Scripts:**
- `scripts/list_github_repos.sh` - List accessible GitHub repositories
- `scripts/mirror_github_repo.sh` - Mirror clone from GitHub
- `scripts/migrate_to_forgejo.sh` - Push repository to Forgejo
- `scripts/batch_migrate.sh` - Batch migrate all repositories
- `scripts/verify_migration.sh` - Verify migration success
- `scripts/compare_repo_counts.sh` - Compare repo counts
- `scripts/update_local_remotes.sh` - Update local git remotes

### 4. Repository Migration

Successfully migrated 5 repositories with naming convention:

| GitHub Repository | Forgejo Repository |
|-------------------|-------------------------|
| `jperry303/epytype` | `Epytype/epytype` |
| `jperry303/epytype-docstore` | `Epytype/docstore` |
| `jperry303/epytype-kernel` | `Epytype/kernel` |
| `jperry303/epytype-lang` | `Epytype/lang` |
| `jperry303/epytype-spec` | `Epytype/spec` |

**Naming Convention:**
- `epytype-X` format repositories are renamed to `X` in Forgejo
- `epytype` (base repository) keeps its original name
- All repositories are under the `Epytype` organization

### 5. Testing and Verification

- Test migration completed: `Epytype/epytype-forgejo-dry-run`
- Verified push-to-create works for organizations
- Confirmed all branches and tags migrated
- Tested SSH access and repository cloning

---

## Repository Access Information

### Web Interface
- **Forgejo URL:** https://repo.epytype.org
- **Organization:** https://repo.epytype.org/Epytype

### SSH Access
- **SSH User:** `git`
- **SSH Host:** `repo.epytype.org`
- **SSH Port:** 2222 (container), 22 (host)

**Clone via SSH:**
```bash
git clone git@repo.epytype.org:Epytype/epytype.git
git clone git@repo.epytype.org:Epytype/docstore.git
git clone git@repo.epytype.org:Epytype/kernel.git
git clone git@repo.epytype.org:Epytype/lang.git
git clone git@repo.epytype.org:Epytype/spec.git
```

### HTTPS Access
```bash
git clone https://repo.epytype.org/Epytype/epytype.git
```

### API Access
- **API Endpoint:** https://repo.epytype.org/api/v1
- **API Token:** Stored in `.env` as `FORGEJO_ADMIN_TOKEN`

---

## Ansible Configuration

### Updated Files

**Playbook:** `/Users/H23/logicallight/Epytype/ops/setup_epytype.yml`
- Added tags: `repo-server`, `forgejo`, `forgejo_push_create_org`, `forgejo_users`

**Forgejo Role:** `/Users/H23/logicallight/Epytype/ops/roles/forgejo_container/`
- `defaults/main.yml` - Added `forgejo_https_enabled: false`, Forgejo user management variables
- `tasks/main.yml` - Added user management tasks, fixed syntax
- `tasks/push_create_org.yml` - New task for organization push-to-create
- `tasks/users.yml` - New task for user/org/repo management
- `templates/docker-compose.yml.j2` - Added push-to-create environment variables
- `handlers/main.yml` - Added "Restart Forgejo" handler

### Running Ansible Tags

```bash
cd /Users/H23/logicallight/Epytype/ops

# Update Forgejo configuration only
ansible-playbook setup_epytype.yml --tags repo_server,forgejo -i inventory/epytype

# Enable push-to-create for organizations
ansible-playbook setup_epytype.yml --tags repo_server,forgejo_push_create_org -i inventory/epytype

# Manage Forgejo users (requires variables)
ansible-playbook setup_epytype.yml --tags repo_server,forgejo_users -i inventory/epytype
```

---

## User Management (Optional)

### Forgejo User Variables

Defined in `roles/forgejo_container/defaults/main.yml`:

```yaml
# Forgejo user management (optional)
forgejo_users:
  - username: jdoe
    password: secret123
    email: jdoe@example.com
    admin: false

# Forgejo organization membership (optional)
forgejo_org_members:
  - username: jdoe
    organization: Epytype
    role: member  # or 'admin'

# Forgejo repository access (optional)
forgejo_repo_access:
  - team: developers
    repository: Epytype/website
    access: write  # read, write, or admin
```

---

## Post-Migration Steps

### 1. For Users

Follow the setup guide at `ops/SETUP_GUIDE.md`:
- Add SSH key to Forgejo at https://repo.epytype.org/user/settings/keys
- Test SSH connection: `ssh -T git@repo.epytype.org`
- Clone fresh copies of all repositories
- Update local development workflow

### 2. Archive GitHub Repositories

Do NOT delete immediately. Archive instead:
1. Go to https://github.com/jperry303/epytype/settings
2. Scroll to "Danger Zone" → "Archive this repository"
3. Repeat for all 5 repositories

### 3. Update Documentation and Links

- Update README files with new repository URLs
- Update bookmarks
- Notify team members of new repository locations
- Update CI/CD pipelines to point to new URLs

### 4. Monitor Forgejo

```bash
# Check Forgejo logs
ssh devops@195.201.226.77 'docker logs forgejo'

# Check disk space
ssh devops@195.201.226.77 'df -h'

# Verify backups are enabled
ssh devops@195.201.226.77 'curl -s -H "Authorization: Bearer $HCLOUD_TOKEN" https://api.hetzner.cloud/v1/servers/128490265 | grep backup_window'
```

---

## Migration Script Usage

### Quick Migration (Already Completed)

```bash
cd /Users/H23/logicallight/Epytype/ops/repo_migration/scripts
source /Users/H23/logicallight/Epytype/ops/.env

# List GitHub repositories
./list_github_repos.sh

# Run batch migration (already done)
./batch_migrate.sh github_repos.txt

# Verify migration
./verify_migration.sh github_repos.txt
```

### Single Repository Migration

```bash
# Format: ./migrate_to_forgejo.sh <org/repo> [target_org]
./migrate_to_forgejo.sh jperry303/epytype-kernel Epytype
```

---

## Technical Details

### Forgejo Configuration

**Config File:** `/data/gitea/conf/app.ini` (inside Forgejo container)

**Key Settings:**
```ini
[repository]
ROOT = /data/git/repositories
ENABLE_PUSH_CREATE = true
ENABLE_PUSH_CREATE_ORG = true
```

**Restart Forgejo after config changes:**
```bash
ssh devops@195.201.226.77 'docker restart forgejo'
```

### Terraform State

**Hetzner Server:**
- Server ID: `128490265`
- Public IP: `195.201.226.77`
- Backups: Enabled (window: 10-14)
- SSH key: Protected from changes that would destroy server

**Cloudflare:**
- Zone ID: `245d6a95015f03d3d5f9e9aa24ef06bd`
- API Token: Configured in `.env`

---

## Git Commits

Relevant commits in `/Users/H23/logicallight/Epytype/ops/`:

1. `feat: Enable push-to-create for Forgejo organizations`
   - Added ENABLE_PUSH_CREATE_ORG to Forgejo config
   - Created push_create_org.yml task
   - Fixed Ansible tags

2. `feat: Add Forgejo user management tasks and push-to-create org support`
   - Created users.yml for managing users, orgs, and repo access
   - Added Forgejo user management variables

3. `feat: Complete GitHub to Forgejo migration and user guide`
   - Migrated all 5 repositories
   - Created SETUP_GUIDE.md for developers
   - Fixed migration scripts to handle errors gracefully

---

## Quick Reference

### Repository URLs

| Repository | Web URL | SSH URL |
|------------|---------|---------|
| epytype | https://repo.epytype.org/Epytype/epytype | git@repo.epytype.org:Epytype/epytype.git |
| docstore | https://repo.epytype.org/Epytype/docstore | git@repo.epytype.org:Epytype/docstore.git |
| kernel | https://repo.epytype.org/Epytype/kernel | git@repo.epytype.org:Epytype/kernel.git |
| lang | https://repo.epytype.org/Epytype/lang | git@repo.epytype.org:Epytype/lang.git |
| spec | https://repo.epytype.org/Epytype/spec | git@repo.epytype.org:Epytype/spec.git |

### One-Line Clone All Repos

```bash
mkdir -p ~/Epytype && cd ~/Epytype && \
git clone git@repo.epytype.org:Epytype/epytype.git && \
git clone git@repo.epytype.org:Epytype/docstore.git && \
git clone git@repo.epytype.org:Epytype/kernel.git && \
git clone git@repo.epytype.org:Epytype/lang.git && \
git clone git@repo.epytype.org:Epytype/spec.git
```

---

## Summary

The migration from GitHub to Forgejo is complete. All 5 repositories have been successfully migrated to the Epytype organization on Forgejo. The push-to-create functionality is enabled, allowing future repositories to be automatically created when pushed. Ansible roles have been updated with proper tags and user management capabilities. Users should follow `ops/SETUP_GUIDE.md` to set up their access and clone fresh copies of the repositories.

**Migration Status: COMPLETE**  
**Next Steps:** Archive GitHub repos, update documentation, notify team members.
