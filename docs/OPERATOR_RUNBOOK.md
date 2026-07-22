# Ops Operator Runbook

Consolidated SOP for the current `ops/` repo. Use this as the top-level workflow map, then drop into the linked docs for setup details and inventory references.

## Doc map

- workstation bootstrap: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- automation inventory and tags: [FEATURES.md](FEATURES.md)
- email routing notes: [EMAIL_CONFIG.md](EMAIL_CONFIG.md)
- docs index: [README.md](README.md)

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

- working `ansible`, `terraform`, `python3`, and `git`
- local credentials loaded from `ops/` with `source ./bin/loadenv.sh`
- access to the inventory hosts you intend to manage

## Standard operating sequence

### 1. Bootstrap a workstation

1. Follow [SETUP_GUIDE.md](SETUP_GUIDE.md).
2. From `ops/`, load credentials:
   ```bash
   source ./bin/loadenv.sh
   ```
3. If you changed docs, playbooks, roles, or tags, run:
   ```bash
   python3 bin/check_features_sync.py
   ```

### 2. Manage Terraform and DNS state

For normal Terraform-driven changes, use:

```bash
apb terraform.yml -t terraform
```

Expected behavior:

- uses Ansible vault decryption via `ansible.cfg` and `.vault_devops` to render `tf/spaceship.auto.tfvars.json` from `tf/spaceship.auto.tfvars.json.j2`
- initializes `tf/` if needed
- runs `terraform plan -detailed-exitcode`
- applies automatically when drift is detected
- reads Terraform outputs and prints a DNS summary for the managed domain

Use raw Terraform in `tf/` only for focused debugging or module work.

### 3. Baseline the public web host and Pharos edge

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
- the TLS certificate exists under `/etc/letsencrypt/live/pharos.llight.io/`
- nginx access/error logs exist at the configured Pharos log paths

### 4. Build Pharos artifacts on the controller

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
- Docker Compose orchestration lives under `../pharos/cross/docker`
- packaged artifacts are emitted under `../pharos/dist/packages`

Verification:

- the play prints the packaged artifacts whose checksums changed during the run
- the expected package format appears in `../pharos/dist/packages`

### 5. Deploy the Pharos runtime package

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

### 6. Deploy a Pharos app bundle

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
- renders the finalized app root on the controller
- packages it into a tarball under `../pharos/dist/release/app`
- stages the bundle via `roles/ll_repo`
- extracts it into `/srv/pharos/apps/<app_id>`
- verifies `pharos.app.json` exists and preserves relocatable `app_root` metadata
- prunes older retained app bundles

### 7. Run administrative maintenance

`admin.yml` always requires a host limit.

Examples:

```bash
apb admin.yml -l web0
apb admin.yml -l web0 -t update_reboot
apb admin.yml -l web0 -t tailscale_machine
apb admin.yml -l web0 -t tailscale_policy
```

Use this playbook for routine package maintenance and Tailscale operations on an explicitly limited host set.

### 8. Run key and certificate workflows

`kymstr.yml` is the entry point for `roles/keymaster`. Most actions are intentionally gated by `never`, so combine a host limit with explicit tags.

Examples:

```bash
apb kymstr.yml -l web0 -t ssh-auth
apb kymstr.yml -l web0 -t ssh-key
apb kymstr.yml -l web0 -t gen-csr
apb kymstr.yml -l web0 -t cert
```

Use [FEATURES.md](FEATURES.md) for the current task-tag inventory.

## Recovery notes

- If the docs guard fails after an `ops/` edit, update the docs inventory before finishing.
- If Terraform state needs local cleanup because infrastructure was already removed out of band, prefer updating `tf/` and pruning local state rather than forcing remote destroys.
- When in doubt, narrow Ansible runs with `-l` and the smallest useful `-t` selection.
