# Forgejo Repository Migration - User Guide

## Overview

All repositories have been migrated from GitHub to Forgejo at `https://repo.epytype.org`. This guide will help you:
1. Set up SSH access to Forgejo
2. Check out fresh copies of all repositories
3. Update your local development workflow

---

## Step 1: Set Up SSH Access for Forgejo

### 1.1 Check Existing SSH Key

```bash
# Check if you have an SSH key
ls -la ~/.ssh/id_ed25519* 2>/dev/null || ls -la ~/.ssh/id_rsa* 2>/dev/null
```

If you don't have an SSH key, create one:
```bash
# Create ed25519 key (recommended)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Or create RSA key (if needed)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

### 1.2 Add SSH Key to Forgejo

1. Copy your public key:
   ```bash
   # For ed25519
   cat ~/.ssh/id_ed25519.pub
   
   # For RSA
   cat ~/.ssh/id_rsa.pub
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

# You should see something like:
# Welcome to Forgejo, <your_username>!
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
mkdir -p ~/epytype-repos
cd ~/epytype-repos

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
ls -la ~/epytype-repos/

# Check remotes for each repo
cd ~/epytype-repos/epytype && git remote -v
# Should show:
# origin  git@repo.epytype.org:Epytype/epytype.git (fetch)
# origin  git@repo.epytype.org:Epytype/epytype.git (push)
```

---

## Step 3: Update Local Development Workflow

### 3.1 If You Have Existing Local Copies

If you have existing local copies with unpushed work:

```bash
# Navigate to your existing local copy
cd /path/to/old/epytype-clone

# Check status
git status
git log --oneline --decorate --graph --all

# Add new Forgejo remote
git remote add forgejo git@repo.epytype.org:Epytype/epytype.git

# Push any unpushed work to Forgejo
git push forgejo main

# Or push all branches
git push forgejo --all

# Set Forgejo as default remote
git remote remove origin  # Remove old GitHub remote
git remote rename forgejo origin

# Update local main branch
git branch --set-upstream-to=origin/main main
```

### 3.2 Update All Existing Local Repos

If you have local clones of the old GitHub repos:

```bash
# For each existing local repository:
cd /path/to/old/epytype
git remote set-url origin git@repo.epytype.org:Epytype/epytype.git
git remote -v  # Verify
git fetch origin
git branch --set-upstream-to=origin/main main

# Repeat for other repos:
# epytype-docstore -> Epytype/docstore
# epytype-kernel -> Epytype/kernel
# epytype-lang -> Epytype/lang
# epytype-spec -> Epytype/spec
```

### 3.3 Update CI/CD References

Update any CI/CD pipelines, GitHub Actions, or automation scripts to point to the new URLs:

**Old:** `https://github.com/jperry303/epytype.git`
**New:** `https://repo.epytype.org/Epytype/epytype.git`

**Old:** `git@github.com:jperry303/epytype.git`
**New:** `git@repo.epytype.org:Epytype/epytype.git`

---

## Step 4: Verify Everything Works

### 4.1 Check Repository Content

```bash
cd ~/epytype-repos/epytype

# Verify branches
git branch -a

# Verify tags
git tag -l

# Check recent commits
git log --oneline --decorate -10
```

### 4.2 Test Push Access

```bash
cd ~/epytype-repos/epytype

# Make a test change
echo "# Test" >> TEST.md
git add TEST.md
git commit -m "test: Verify push access to Forgejo"

# Push to Forgejo
git push origin main

# Clean up (optional)
git reset --hard HEAD~1
git push origin main --force
```

---

## Quick Reference

### Repository URLs

```bash
# Epytype (main repo)
git@repo.epytype.org:Epytype/epytype.git
https://repo.epytype.org/Epytype/epytype.git

# Docstore
git@repo.epytype.org:Epytype/docstore.git
https://repo.epytype.org/Epytype/docstore.git

# Kernel
git@repo.epytype.org:Epytype/kernel.git
https://repo.epytype.org/Epytype/kernel.git;

# Lang
git@repo.epytype.org:Epytype/lang.git
https://repo.epytype.org/Epytype/lang.git;

# Spec
git@repo.epytype.org:Epytype/spec.git;
https://repo.epytype.org/Epytype/spec.git;
```

### One-Line Clone All Repos

```bash
mkdir -p ~/epytype-repos && cd ~/epytype-repos && \
git clone git@repo.epytype.org:Epytype/epytype.git && \
git clone git@repo.epytype.org:Epytype/docstore.git && \
git clone git@repo.epytype.org:Epytype/kernel.git && \
git clone git@repo.epytype.org:Epytype/lang.git && \
git clone git@repo.epytype.org:Epytype/spec.git
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
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### Push Rejected

```bash
# If push is rejected, check:
git status
git fetch origin
git rebase origin/main
git push origin main
```

### Repository Not Found

```bash
# Verify repository exists
curl -s https://repo.epytype.org/Epytype/epytype | head -5

# Check organization
curl -s https://repo.epytype.org/Epytype | head -5
```

---

## Next Steps

1. ✅ **Archive GitHub repositories** (don't delete yet)
   - Go to https://github.com/jperry303/epytype/settings
   - Scroll to "Danger Zone" → "Archive this repository"
   - Repeat for all 5 repos

2. ✅ **Update documentation** with new repository URLs

3. ✅ **Notify team members** of the new repository locations

4. ✅ **Update bookmarks** and any automation scripts

---

## Summary

**Migration Complete!** 🎉

All repositories are now on Forgejo:
- https://repo.epytype.org/Epytype/epytype
- https://repo.epytype.org/Epytype/docstore
- https://repo.epytype.org/Epytype/kernel
- https://repo.epytype.org/Epytype/lang
- https://repo.epytype.org/Epytype/spec

**Fresh clones recommended** - Start clean with the new Forgejo repositories.
