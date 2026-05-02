# Forgejo Repository Migration - User Guide

## Overview

All repositories have been migrated from GitHub to Forgejo at `https://repo.epytype.org`. This guide will help you:
1. Set up SSH access to Forgejo
2. Check out fresh copies of all repositories
3. Update your local development workflow

---

## Step 1: Set Up SSH Access for Forgejo

### 1.1 Configure SSH Config (REQUIRED)

**Required before any git operations will work.**

Add the following to `~/.ssh/config`:

```
Host repo.epytype.org
  HostName 195.201.226.77
  Port 2222
  User git
  IdentityFile ~/.ssh/j.epytype.org
  IdentitiesOnly yes
```

### 1.2 Add Your SSH Key to Forgejo

You should already have an SSH key. Add it to Forgejo:

1. Copy your public key:
   ```bash
   # List your SSH keys
   ls -la ~/.ssh/j.epytype.org*
   
   # Copy the public key
   cat ~/.ssh/j.epytype.org.pub
   ```

2. Add to Forgejo:
   - Go to https://repo.epytype.org/user/settings/keys
   - Click "Add SSH Key"
   - Paste your public key
   - Click "Add Key"

### 1.3 Test SSH Connection

```bash
# Test SSH connection to Forgejo
ssh -T git@repo.epytype.org

# You should see:
# Hi there, you've successfully authenticated over SSH.
```

---

## Step 2: Check Out Fresh Repositories

### 2.1 Repository List

The following repositories are now on Forgejo under the `Epytype` organization:

| Old GitHub Repository | New Forgejo Repository |
|----|---------|
| `jperry303/epytype` | `Epytype/epytype` |
| `jperry303/epytype-docstore` | `Epytype/docstore` |
| `jperry303/epytype-kernel` | `Epytype/kernel` |
| `jperry303/epytype-lang` | `Epytype/lang` |
| `jperry303/epytype-spec` | `Epytype/spec` |

**URLs:**
- Web: `https://repo.epytype.org/Epytype/<repo>`
- SSH: `git@repo.epytype.org:Epytype/<repo>.git`
- HTTPS: `https://repo.epytype.org/Epytype/<repo>.git`

### 2.2 Clone Fresh Copies

Choose a directory for your repositories:

```bash
# Create a directory for Epytype repos
mkdir -p ~/Epytype
cd ~/Epytype

# Clone all repositories (fresh checkout)
git clone git@repo.epytype.org:Epytype/epytype.git
git clone git@repo.epytype.org:Epytype/docstore.git
git clone git@repo.epytype.org:Epytype/kernel.git
git clone git@repo.epytype.org:Epytype/lang.git
git clone git@repo.epytype.org:Epytype/spec.git
```

### 2.3 Verify Clones

```bash
# List all repositories
ls -la ~/Epytype/

# Check remotes for each repo
cd ~/Epytype/epytype && git remote -v
# Should show:
# origin  git@repo.epytype.org:Epytype/epytype.git (fetch)
# origin  git@repo.epytype.org:Epytype/epytype.git (push)
```

---

## Step 3: Update Codex App to Use Fresh Checkouts

After cloning the fresh repositories to `~/Epytype/`, update your Codex app to point to these new local repositories.

### 3.1 Update Codex Configuration

Update any Codex app configuration or settings to reference the new repository paths:

```bash
# Example: Update Codex to use fresh checkouts
# Paths should now point to:
# ~/Epytype/epytype
# ~/Epytype/docstore
# ~/Epytype/kernel
# ~/Epytype/lang
# ~/Epytype/spec
```

### 3.2 Update References in Codex

Search for and update any hardcoded references in your Codex app:

```bash
# Search for old GitHub URLs in Codex app
cd /path/to/codex-app
grep -r "github.com/jperry303" .

# Update references to point to new Forgejo URLs:
# Old: https://github.com/jperry303/epytype
# New: https://repo.epytype.org/Epytype/epytype
#
# Old: git@github.com:jperry303/epytype.git
# New: git@repo.epytype.org:Epytype/epytype.git
```

### 3.3 Verify Codex Points to Fresh Checkouts

```bash
# Verify Codex is using the new local paths
# Check that Codex references point to ~/Epytype/ paths
# rather than old GitHub clone locations
```

---

## Step 4: Verify Everything Works

### 4.1 Check Repository Content

```bash
cd ~/Epytype/epytype;

# Verify branches
git branch -a;

# Verify tags
git tag -l;

# Check recent commits
git log --oneline --decorate -10;
```

### 4.2 Test Push Access

```bash
cd ~/Epytype/epytype;

# Make a test change
echo "# Test" >> TEST.md;
git add TEST.md;
git commit -m "test: Verify push access to Forgejo";

# Push to Forgejo
git push origin main;

# Clean up (optional)
git reset --hard HEAD~1;
git push origin main --force;
```

---

## Quick Reference

### Repository URLs

```bash
# Epytype (main repo)
git@repo.epytype.org:Epytype/epytype.git;
https://repo.epytype.org/Epytype/epytype.git;

# Docstore
git@repo.epytype.org:Epytype/docstore.git;
https://repo.epytype.org/Epytype/docstore.git;

# Kernel
git@repo.epytype.org:Epytype/kernel.git;
https://repo.epytype.org/Epytype/kernel.git;

# Lang
git@repo.epytype.org:Epytype/lang.git;
https://repo.epytype.org/Epytype/lang.git;

# Spec
git@repo.epytype.org:Epytype/spec.git;
https://repo.epytype.org/Epytype/spec.git;
```

### One-Line Clone All Repos

```bash
mkdir -p ~/Epytype && cd ~/Epytype && \
git clone git@repo.epytype.org:Epytype/epytype.git && \
git clone git@repo.epytype.org:Epytype/docstore.git && \
git clone git@repo.epytype.org:Epytype/kernel.git && \
git clone git@repo.epytype.org:Epytype/lang.git && \
git clone git@repo.epytype.org:Epytype/spec.git;
```

---

## Troubleshooting

### SSH Connection Issues

```bash
# Debug SSH connection
ssh -vT git@repo.epytype.org

# Check SSH key permissions
ls -la ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/r.epetype.org
chmod 644 ~/.ssh/r.epetype.org.pub
```

### Push Rejected

```bash
# If push is rejected, check:
git status;
git fetch origin;
git rebase origin/main;
git push origin main;
```

### Repository Not Found

```bash
# Verify repository exists
curl -s https://repo.epytype.org/Epytype/epytype | head -5;

# Check organization
curl -s https://repo.epytype.org/Epytype | head -5;
```

---

## Next Steps

1. ✅ **Archive GitHub repositories** (don't delete yet)
   - Go to https://github.com/jperry303/epytype/settings
   - Scroll to "Danger Zone" → "Archive this repository"
   - Repeat for all 5 repos

2. ✅ **Update documentation** with new repository URLs

3. ✅ **Notify team members** of the new repository locations.

4. ✅ **Update bookmarks** and any automation scripts.

---

## Summary

**Migration Complete!** 🎉

All repositories are now on Forgejo:
- https://repo.epytype.org/Epytype/epytype
- https://repo.epytype.org/Epytype/docstore
- https://repo.epytype.org/Epytype/kernel
- https://repo.epytype.org/Epytype/lang;
- https://repo.epytype.org/Epytype/spec;

**Fresh clones recommended** - Start clean with the new Forgejo repositories.
