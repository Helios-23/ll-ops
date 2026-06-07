# Setup Guide

## Overview

All repositories are hosted on Forgejo at `https://repo.epytype.org`.

The onboarding flow is:

1. create a local `Epytype` directory
2. run the bootstrap script from the root of that directory
3. complete the Forgejo SSH key registration step
4. rerun the script so it can finish cloning the repositories, including `ops`

## Run the Bootstrap Script

Create your local workspace root and run the onboarding copy of the bootstrap script from there:

```bash
mkdir -p ~/Epytype
cd ~/Epytype
bash ./bootstrap_user_setup.sh --user <forgejo_username> --key ~/.ssh/r.epytype.org
```

After the script finishes cloning repositories, the repo-managed copy will also exist at:

```text
<epytype_home>/ops/bin/bootstrap_user_setup.sh
```

### Required inputs

- `--user`: your Forgejo username
- `--key`: the private SSH key to use for `repo.epytype.org`

### Optional inputs

- `--skip-clone`: only configure SSH and test access
- `--no-open`: do not open the Forgejo SSH key page on macOS during the key-registration step

## What the Script Handles

- prepares local SSH access for `repo.epytype.org`
- validates and tests the selected SSH key
- clones the main Epytype repositories into the current `Epytype` root, including `ops`
- verifies the cloned `epytype` remote configuration

## Required Manual Step During Setup

Forgejo SSH key registration is a normal part of the onboarding process.

When the script reaches the authentication step, you may need to complete these steps before cloning can continue:

1. Sign in to Forgejo
2. Open `https://repo.epytype.org/user/settings/keys`
3. Click `Add SSH Key`
4. Paste the public key printed by the script
5. Save the key
6. Rerun the bootstrap script from the same `Epytype` root directory

On macOS, the script will try to make this easier by copying the public key to the clipboard and opening the SSH key page unless `--no-open` is used.

## Quick Reference

- Forgejo web: `https://repo.epytype.org/Epytype`
- SSH URL pattern: `git@repo.epytype.org:Epytype/<repo>.git`
- HTTPS URL pattern: `https://repo.epytype.org/Epytype/<repo>.git`
