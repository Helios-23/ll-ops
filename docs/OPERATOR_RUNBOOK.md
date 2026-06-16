# Epytype Ops Operator Runbook

Consolidated SOP for the `ops/` repo. Use this document as the top-level workflow map, then drop into the linked specialist documents for host-specific or subsystem-specific detail.

## Doc map

- workstation bootstrap: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- automation inventory and tags: [FEATURES.md](FEATURES.md)
- AI server operations, model inventory, and deployment testing: [AI_SERVER.md](AI_SERVER.md)
- email address setup and routing: [EMAIL_CONFIG.md](EMAIL_CONFIG.md)
- repo0 NBDE planning: [REPO0_LUKS_NBDE_PLAN.md](REPO0_LUKS_NBDE_PLAN.md)
- Forgejo/GitHub repo migration tooling: [repo_migration/README.md](repo_migration/README.md)

## Environment and source of truth

- default inventory: `inventory/epytype` via `ansible.cfg`
- group vars: `group_vars/all`, `group_vars/prod`, `group_vars/prod_ai`
- Terraform root: `tf/`
- helper scripts: `bin/`
- SSH public keys: `keys/ssh/`
- role implementations: `roles/`


Required local prerequisites:

- the `kpxc/` credentials directory under `ops/`
- working `ansible`, `terraform`, `python3`, `git`, and `ansible-vault`
- local checkout of sibling repos used by release automation: `../epytype`, `../lantern`

## Standard operating sequence

### 1. Bootstrap or recover a workstation

1. Follow [SETUP_GUIDE.md](SETUP_GUIDE.md).
2. Confirm credential loading succeeds: `source ./bin/loadenv.sh`.
3. Validate documentation inventory if you changed `ops/`: `python3 bin/check_features_sync.py`.

### 2. Plan and apply infrastructure

Use `terraform.yml` for normal Terraform-driven changes:

```bash
apb terraform.yml -t terraform
```

Expected behavior:

- initializes `tf/` if needed
- runs `terraform plan -detailed-exitcode`
- applies automatically on drift
- syncs host output data back into `inventory/epytype`

Verify:

- review Terraform plan/apply output
- confirm expected inventory lines were updated
- if DNS or host outputs changed, check the generated values in Terraform outputs

Use raw Terraform in `tf/` only for focused debugging, module work, or recovery outside the playbook wrapper.

### 3. Establish baseline hosts

Repo server baseline:

```bash
apb setup_epytype.yml -l repo0
```

AI server baseline:

```bash
apb setup_epytype.yml -l gex0
```

Narrow to role/task areas for incremental work:

```bash
apb setup_epytype.yml -l repo0 -t forgejo
apb setup_epytype.yml -l repo0 -t forgejo_pull
apb setup_epytype.yml -l repo0 -t forgejo_users
apb setup_epytype.yml -l gex0 -t ai_rig
apb setup_epytype.yml -l gex0 -t lantern
apb setup_epytype.yml -l gex0 -t pull_models
```

Verification:

- package and service setup completes without changed tasks on a second run when steady-state is expected
- public endpoints and reverse proxy routes respond as expected
- any role-specific tags used are cross-checked against [FEATURES.md](FEATURES.md)

Repo0 Forgejo pull access:

```bash
apb setup_epytype.yml -l repo0 -t forgejo_pull
```

This role installs the local `devops.epytype.org` SSH keypair onto repo0, pins SSH to use it for `repo.epytype.org`, adds the Forgejo host key, and adds a git URL rewrite for HTTPS-to-SSH fallback during local builds.

Note: the SSH config points to `127.0.0.1:2222` on repo0, uses `HostKeyAlias repo.epytype.org`, and pins the reduced RSA/KEX/cipher set that works with the repo host’s FIPS SSH path. That avoids the Cloudflare-proxied public hostname while keeping known-hosts stable across redeploys.

### 4. Run administrative maintenance

Full admin role against a limited host set:

```bash
apb admin.yml -l repo0
```

Patch and reboot workflow:

```bash
apb admin.yml -l repo0 -t update_reboot
```

Tailscale-specific workflows:

```bash
apb admin.yml -l repo0 -t tailscale_machine
apb admin.yml -l repo0 -t tailscale_policy
```

Operator rule: `admin.yml` requires `-l/--limit`. `inventory/epytype` is already configured in `ansible.cfg`, so do not repeat `-i` unless you are intentionally overriding the default inventory.

### 5. Manage repo0 unattended unlock

Use `repo0_nbde.yml` only after the host is already installed on LUKS and the Clevis/Tang inputs are ready:

```bash
apb repo0_nbde.yml -t luks_nbde
```

Cross-check with [REPO0_LUKS_NBDE_PLAN.md](REPO0_LUKS_NBDE_PLAN.md) before making unlock-path changes.

### 6. Operate key and certificate workflows

`kymstr.yml` is the entry point for `roles/keymaster`. Most actions are guarded by `never`, so always combine a host limit with explicit tags.

Common task areas:

```bash
apb kymstr.yml -l repo0 -t ssh-auth
apb kymstr.yml -l repo0 -t ssh-key
apb kymstr.yml -l repo0 -t gen-csr
apb kymstr.yml -l repo0 -t cert
```

What each area covers:

- `install`: install `pyOpenSSL`
- `encrypt`: vault-encrypt local certificate artifacts
- `gen-ssh` / `ssh-gen`: generate local SSH keypairs from `auth_keys`
- `gen-csr`: generate local private keys and CSRs
- `check-csr`: inspect CSR subject output
- `ssh-auth`: remove unauthorized keys and install allowed keys
- `ssh-auth-review`: generate a local access report
- `ssh-key-report`: collect deployed key fingerprints
- `ssh-key`: install automation keys on remote hosts
- `cert`: copy certs and private keys to remote SSL paths
- `mysql`: run the MySQL helper include

Verification:

- inspect generated local files before deployment
- confirm remote `authorized_keys` content when using `ssh-auth`
- validate cert/key ownership and mode after `cert` or `ssh-key`

### 7. Operate the AI stack

Primary AI workflows live under `setup_epytype.yml` and `roles/ai_rig`.

Common commands:

```bash
apb setup_epytype.yml -l gex0 -t ollama
apb setup_epytype.yml -l gex0 -t pull_models
apb setup_epytype.yml -l gex0 -t show_models
apb setup_epytype.yml -l gex0 -t webui
```

Use the specialist docs for runtime expectations and testing:

- [AI_SERVER.md](AI_SERVER.md)

### 8. Operate the Lantern site

Lantern shares `gex0` with the AI stack. Its public entrypoint is `https://lantern.epytype.org`, and the proxy roles keep the Lantern and AI nginx vhosts separate while both remain enabled.

Common command:

```bash
apb setup_epytype.yml -l gex0 -t lantern
```

The Lantern runtime defaults to `127.0.0.1:7323`, so nginx proxies there unless the service is reconfigured.

Verification:

- `curl -I https://lantern.epytype.org`
- confirm `/etc/nginx/sites-available/lantern.epytype.org.conf` and `/etc/nginx/sites-enabled/lantern.epytype.org.conf` exist
- confirm `/etc/nginx/sites-available/ai.epytype.org.conf` and `/etc/nginx/sites-enabled/ai.epytype.org.conf` exist
- confirm `/var/log/nginx/lantern.access.log` and `/var/log/nginx/lantern.error.log` are being written

### 8b. Build and deploy the Lantern `.deb`

Run this from `ops/` on the repo server after the Lantern and Epytype binaries are available in sibling checkouts:

```bash
apb lantern-release-deploy.yml -l gex0
```

What it does:

- builds `lantern/dist/release/deb/lantern_<version>_<arch>.deb` from the local Lantern checkout
- copies the package to `gex0`
- installs the package with `apt`
- enables and starts `lantern.service` and `lantern-ha.service`

The build step expects `../epytype/dist/binaries` to contain the matching `epytype` and `epm` release binaries.

### 9. Prepare and publish releases

`github-release.yml` is the entry point for `roles/epytype_release`.

Epytype release:

```bash
apb github-release.yml -t epytype
```

Lantern release:

```bash
apb github-release.yml -t lantern
```

Useful overrides:

```bash
apb github-release.yml -t epytype -e epytype_release_number=0
apb github-release.yml -t epytype -e epytype_release_version=0.1.1
```

The role performs this sequence:

1. validate version inputs and repo presence
2. refuse a dirty working tree unless explicitly allowed
3. read the current version from repo-specific source files
4. compute the next version or accept an explicit override
5. update tracked version references and release markers
6. run repo-specific release checks
7. commit release prep, create tag, and push `HEAD:release`
8. optionally mirror branch and tag to GitHub

Verification:

- inspect the generated version and tag before push
- confirm release checks passed
- verify Forgejo push succeeded
- if GitHub mirroring is enabled, confirm the mirror branch and tag landed there too

Recovery note: when release prep has already changed files locally, examine the diff before rerunning. Do not use dirty-tree overrides casually.

### 10. Run repository migration tooling

Migration utilities live under `repo_migration/`. Start with:

- [repo_migration/README.md](repo_migration/README.md)
- [repo_migration/QUICKSTART.md](repo_migration/QUICKSTART.md)
- [repo_migration/TEST_GUIDE.md](repo_migration/TEST_GUIDE.md)

Use these only for Forgejo/GitHub migration work; they are not part of the baseline host provisioning flow.

## Change management for `ops/`

When you add or reshape automation in `ops/`:

1. update [FEATURES.md](FEATURES.md) for playbook, role, or tag changes
2. update this runbook when the operator-facing procedure changes
3. keep [README.md](../README.md) and [docs/README.md](README.md) pointing at the current doc set
4. run `python3 bin/check_features_sync.py`

The guard script checks inventory sync for `FEATURES.md`. The runbook update requirement is enforced by repo instructions in `ops/AGENTS.md` and by keeping this document in the required doc root.
