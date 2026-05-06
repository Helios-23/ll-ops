# SSH Setup, Repository Access & Checkout Guide

## Overview

All repositories are hosted on Forgejo at `https://repo.epytype.org`. This guide covers:
1. SSH setup
2. Cloning fresh repository copies
3. Verifying access

## Step 1: Set Up SSH Access

### 1.1 Add Global SSH Preconfiguration

Add this to `~/.ssh/config`:

```sshconfig
IgnoreUnknown UseKeychain
Host *
    AddressFamily inet
    Protocol 2
    ControlMaster auto
    ControlPath ~/.ssh/socket/%r@%h-%p
    ControlPersist 600
    PreferredAuthentications=publickey,password
    UseKeychain yes
    AddKeysToAgent yes
    Ciphers aes256-ctr,aes256-gcm@openssh.com,aes192-ctr,aes128-ctr,aes128-gcm@openssh.com
    MACs hmac-sha2-256,hmac-sha2-512,hmac-sha1
    KexAlgorithms diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256,ecdh-sha2-nistp256,ecdh-sha2-nistp384
    PubkeyAcceptedAlgorithms ssh-ed25519,rsa-sha2-256,rsa-sha2-512,ecdsa-sha2-nistp256
    HostKeyAlgorithms ssh-ed25519,rsa-sha2-256,rsa-sha2-512,ecdsa-sha2-nistp256
```

### 1.2 Add Forgejo Host Configuration (Required)

Add this block to the same `~/.ssh/config` file and chnage the user name to your own:

```sshconfig
# Forgejo (repo.epytype.org) SSH config
# Add your public key in Forgejo: Settings -> SSH / GPG Keys
Host repo.epytype.org
  HostName 195.201.226.77
  Port 2222
  User git
  IdentityFile ~/.ssh/r.epytype.org
  IdentitiesOnly yes
```

Update `IdentityFile` if your local key path is different.

### 1.3 Create SSH Control Socket Directory

Run:

```bash
mkdir -p ~/.ssh/socket
chmod 700 ~/.ssh/socket
```

### 1.4 Add Your Public Key to Forgejo

1. Confirm your key pair exists:
   ```bash
   ls -la ~/.ssh/r.epytype.org*
   ```
2. Copy your public key:
   ```bash
   cat ~/.ssh/r.epytype.org.pub
   ```
3. Add it in Forgejo:
   - https://repo.epytype.org/user/settings/keys
   - Click `Add SSH Key`
   - Paste key and save

### 1.5 Test SSH Authentication

```bash
ssh -T git@repo.epytype.org
```

Expected output includes `Hi there, you've successfully authenticated over SSH.`

## Step 2: Clone Fresh Repositories

```bash
mkdir -p ~/Epytype
cd ~/Epytype

git clone git@repo.epytype.org:Epytype/epytype.git
git clone git@repo.epytype.org:Epytype/docstore.git
git clone git@repo.epytype.org:Epytype/kernel.git
git clone git@repo.epytype.org:Epytype/lang.git
git clone git@repo.epytype.org:Epytype/spec.git
```

## Step 3: Verify Remotes

```bash
cd ~/Epytype/epytype
git remote -v
```

Expected `origin`:
`git@repo.epytype.org:Epytype/epytype.git`

## Quick Reference

- Forgejo web: `https://repo.epytype.org/Epytype`
- SSH URL pattern: `git@repo.epytype.org:Epytype/<repo>.git`
- HTTPS URL pattern: `https://repo.epytype.org/Epytype/<repo>.git`
