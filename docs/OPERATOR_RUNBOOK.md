# Ops Operator Runbook

Consolidated SOP for the current `ops/` repo. Use this as the top-level workflow map, then drop into the linked docs for setup details and inventory references.

## Doc map

- workstation bootstrap: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- automation inventory and tags: [FEATURES.md](FEATURES.md)
- docs index: [README.md](README.md)
- Ansible Vault guard design and credential audit: [VAULT_COMMIT_GUARD_PLAN.md](VAULT_COMMIT_GUARD_PLAN.md)

## Environment and source of truth

- default inventory: `inventory/logicallight`
- group vars: `group_vars/all`, `group_vars/prod`, `group_vars/prod_web`
- Terraform root: `tf/`
- helper scripts: `bin/`
- role implementations: `roles/`
- sibling source checkouts used by build/deploy flows:
  - `../pharos`
  - `../epytype`

Required local prerequisites:

- working `ansible`, `terraform`, `python3`, `git`, and `gitleaks` (`brew install gitleaks` on macOS)
- local credentials loaded from `ops/` with `source ./bin/loadenv.sh`
- access to the inventory hosts you intend to manage

## Standard operating sequence

### 1. Bootstrap a workstation

1. Follow [SETUP_GUIDE.md](SETUP_GUIDE.md).
2. From `ops/`, load credentials:
   ```bash
   source ./bin/loadenv.sh
   ```
3. Enable the repository-managed commit guard once per checkout:
   ```bash
   git config core.hooksPath .githooks
   ```
4. Verify all tracked policy-protected files are encrypted:
   ```bash
   python3 bin/check_ansible_vault_encryption.py
   ```
5. If you changed docs, playbooks, roles, or tags, run:
   ```bash
   python3 bin/check_features_sync.py
   ```

### 2. Protect vaulted files and credential artifacts

The pre-commit hook runs `python3 bin/check_ansible_vault_encryption.py --staged` and validates the exact content in the Git index, then runs `gitleaks git --pre-commit --staged --redact --no-banner` for unexpected secrets. It fails closed if Gitleaks is unavailable. The authoritative GitHub checks run the vault validator and Gitleaks over the repository on pushes and pull requests.

Protected patterns are maintained in `config/ansible-vault-required-files.txt`. They currently require encryption for:

- `group_vars/**/vault.yml`

To encrypt an approved file:

```bash
ansible-vault encrypt path/to/file --vault-id devops@.vault_devops
```

The entire `keys/` directory remains ignored and outside this implementation. Do not add, encrypt, stage, or commit files from it as part of vault-guard rollout.

If the GitHub workflow passes, configure the repository ruleset or `main` branch protection to require the `Verify required Ansible Vault encryption` status check. The workflow reports violations but branch protection is what blocks merging.

See [VAULT_COMMIT_GUARD_PLAN.md](VAULT_COMMIT_GUARD_PLAN.md) for the repository-wide audit and enforcement limitations.

### 3. Manage Terraform and DNS state

For normal Terraform-driven changes, use:

```bash
apb terraform.yml -t terraform
```

This runs in plan-only mode. To actually apply the planned changes, pass the opt-in flag explicitly:

```bash
apb terraform.yml -t terraform -e terraform_apply=true
```

Expected behavior:

- uses Ansible vault decryption via `ansible.cfg` and `.vault_devops` to render `tf/spaceship.auto.tfvars.json` from `tf/spaceship.auto.tfvars.json.j2`
- renders `tf/gcp.auto.tfvars.json` from Ansible vars including `domain`, `gcp_proj_id`, `gcp_region`, and `gcp_zone`
- exports `GOOGLE_APPLICATION_CREDENTIALS` to the Terraform service account key under `keys/tf/terraform-key.json`
- initializes `tf/` if needed
- when the GCP Pharos public IP is not yet present in Terraform state, plans a one-time targeted bootstrap that enables `compute.googleapis.com` and creates the GCP network, subnet, firewall, reserved IP, SSH metadata, and instance; the bootstrap applies only when `terraform_apply=true` is passed
- runs `terraform plan -detailed-exitcode` and reports the result
- applies drift changes only when `terraform_apply=true` is passed; otherwise it prints a warning that planned changes were left unapplied
- protects the GCP network, subnet, firewall, reserved IP, and instance in `tf/main.tf` with `lifecycle { prevent_destroy = true }`, so an apply can never delete and recreate existing infrastructure
- updates the `web0` entry in `inventory/logicallight` from Terraform outputs
- manages the Spaceship DNS record set: A records for the root domain (`@`), `www`, and `pharos` all point at the Pharos public IP, alongside the configured MX records
- reads Terraform outputs and prints an infrastructure and DNS summary for the managed domain

Use raw Terraform in `tf/` only for focused debugging or module work.

### 4. Bootstrap cloud provider credentials

For initial Terraform credential setup on a new workstation or project:

```bash
apb cloud_bootstrap.yml -e cloud_bootstrap_provider=gcp
apb cloud_bootstrap.yml -e cloud_bootstrap_provider=aws
apb cloud_bootstrap.yml -e cloud_bootstrap_provider=azure
```

Expected behavior:

- validates required variables for the selected provider
- enables foundational cloud APIs (GCP)
- creates the service account or IAM user and assigns the required roles
- generates a local JSON key or access key file under `keys/tf/`
- skips key creation when the local key file already exists

Verification:

- GCP: `GOOGLE_APPLICATION_CREDENTIALS=keys/tf/terraform-key.json gcloud auth activate-service-account --key-file=keys/tf/terraform-key.json`
- AWS: check that `keys/tf/aws/access_key.json` exists
- Azure: check that `keys/tf/azure/credentials.json` exists

### 5. Baseline the public web host and Pharos edge

Run the baseline playbook against `web0`:

```bash
apb setup_pharos.yml -l web0
```

Useful narrower runs:

```bash
apb setup_pharos.yml -l web0 -t harden
apb setup_pharos.yml -l web0 -t nginx
apb setup_pharos.yml -l web0 -t certbot_tls
apb setup_pharos.yml -l web0 -t pharos
apb setup_pharos.yml -l web0 -t pharos_nginx
```

Verification:

- `nginx -t` succeeds on the target
- the `pharos.llight.io` vhost files exist under `/etc/nginx/sites-available/` and `/etc/nginx/sites-enabled/`
- the vhost serves one TLS server block per entry in the pharos `domain_list`, each redirecting `/` to its configured `root_url`
- a TLS certificate exists under `/etc/letsencrypt/live/<name>/` for every entry in the pharos `domain_list`
- nginx access/error logs exist at the configured Pharos log paths
- note that initial certificate issuance now uses standalone certbot with nginx temporarily stopped so certbot can bind port 80 directly

### 6. Build Pharos artifacts on the controller

Build all supported targets:

```bash
apb build.yml -t pharos_build
```

Build one target only:

```bash
apb build.yml -t pharos_build -e target=linux-aarch64-gnu
```

Notes:

- the build role runs from `ops/` on the controller
- source checkout is expected at `../pharos`
- the ops-side build version is `pharos_build_release_version` and defaults to `0.7.23`
- when `pharos_build_release_version` is newer than `../pharos/VERSION`, the role bumps `../pharos/VERSION` before building
- the role prebuilds the Rustdoc-backed `dev_docs` assets on the host so Debian packaging uses the current docs flow without requiring a Doxygen step inside the cross-build container
- that host-native `bin/pharos` prebuild is reused when the shared narrow fingerprint of the Rust docs crate, app-build entry regions, and relevant build scripts is unchanged; unrelated Rust runtime changes no longer reinstall it
- app packaging now runs through `pharos build app --packaging`, which isolates temporary sqlite and runtime-state paths inside the controller build tree so dynamic app builds do not touch live `/var/lib/pharos` or `/var/state/pharos`
- build and app deployment call the same ops-owned fingerprint helper, which fails closed if required inputs or source-region markers are missing and does not depend on mutable file ordering or platform-specific checksum tools
- packaged app bundles retain their app-local `app.conf`; deployment installs that runtime configuration as `pharos:pharos` with mode `0640` before restarting the shared runtime
- Docker Compose orchestration lives under `../pharos/cross/docker`
- the default `all` target list currently excludes `macos-universal`; the current cross image ships an invalid `/opt/pharos-db/postgresql/macos-universal/lib/libpq.a` with ELF objects, so ops now fails fast if you explicitly request that target
- packaged artifacts are emitted under `../pharos/dist/packages`

Verification:

- the play prints the packaged artifacts whose checksums changed during the run
- the expected package format appears in `../pharos/dist/packages`

### 7. Deploy the Pharos runtime package

Install the newest staged Pharos package on `web0`:

```bash
apb deploy.yml -l web0 -t pharos_runtime
```

If needed, pass an explicit controller-side package path with `-e pharos_deploy_package_src=/path/to/pharos_<version>.deb`.

Expected behavior:

- resolves or accepts a `pharos_*.deb`
- stages it through `roles/ll_repo`
- installs it on the target host
- restarts `pharos.service` and `pharos-ha.service`
- prunes older retained runtime packages

Verification:

- `systemctl status pharos.service pharos-ha.service`
- confirm the expected package is present under the staged artifact root and installed on the host

### 8. Deploy a Pharos app bundle

Deploy one app bundle to `web0`:

```bash
apb deploy.yml -l web0 -t pharos_app -e app_id=ucal
```

Optional clean deploy:

```bash
apb deploy.yml -l web0 -t pharos_app -e app_id=ucal -e clean_app=true
```

Expected behavior:

- optionally syncs the `../pharos` repo when `update_repo=true`
- reuses the existing host-native Pharos docs renderer when the shared narrow `dev_docs` renderer fingerprint matches, and rebuilds it automatically only when the docs crate, app-build entry regions, or build scripts changed or the binary is missing
- renders the finalized app root on the controller
- packages it into a tarball under `../pharos/dist/release/app`
- stages the bundle via `roles/ll_repo`
- extracts it into `/srv/pharos/apps/<app_id>`
- verifies `pharos.app.json` exists and preserves relocatable `app_root` metadata
- prunes older retained app bundles

Recommended live verification from `ops/` after a runtime or app deploy:

```bash
python3 ../pharos/scripts/live_site_smoke.py -url https://pharos.llight.io/ucal -o
```

### 9. Run administrative maintenance

`admin.yml` always requires a host limit.

Examples:

```bash
apb admin.yml -l web0
apb admin.yml -l web0 -t update_reboot
apb admin.yml -l web0 -t tailscale_machine
apb admin.yml -l web0 -t tailscale_policy
```

Use this playbook for routine package maintenance and Tailscale operations on an explicitly limited host set.

### 10. Run key and certificate workflows

`keymaster.yml` is the entry point for `roles/keymaster`. Most actions are intentionally gated by `never`, so combine a host limit with explicit tags.

Examples:

```bash
apb keymaster.yml -l web0 -t ssh-auth
apb keymaster.yml -l web0 -t ssh-key
apb keymaster.yml -l web0 -t gen-csr
apb keymaster.yml -l web0 -t cert
```

Use [FEATURES.md](FEATURES.md) for the current task-tag inventory.

## Recovery notes

- If the docs guard fails after an `ops/` edit, update the docs inventory before finishing.
- If Terraform state needs local cleanup because infrastructure was already removed out of band, prefer updating `tf/` and pruning local state rather than forcing remote destroys.
- Core GCP resources in `tf/main.tf` (network, subnet, firewall, reserved IP, instance) carry `lifecycle { prevent_destroy = true }`. A planned destroy of any of them is a red flag: do not force it, investigate the plan instead. Removing a resource on purpose requires deleting its lifecycle guard first, then a plan-only run to review.
- When in doubt, narrow Ansible runs with `-l` and the smallest useful `-t` selection.
- The Ansible remote tmp dir is per connection user: `remote_tmp = ~/.ansible/tmp` expands `~` to the remote user's home, so `devops` runs use `/home/devops/.ansible/tmp` and root runs use `/root/.ansible/tmp` and never collide. The temp dir is created as the connection user before `become` elevates to root, so root task privileges do not help if that user cannot write the path. If a run ever fails with `Failed to create temporary directory`, check ownership of the offending path; the legacy shared `/tmp/ansible-remote` (root-owned mode 700 from an old root run) can simply be removed on the host: `rm -rf /tmp/ansible-remote`.
