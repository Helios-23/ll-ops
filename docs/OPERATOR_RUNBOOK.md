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

### Private QA integration environment

Run `sudo python3 provision_pharos_qa_environment.py` on the QA host to preview missing framework payment keys and Dynamic loopback settings; add `--apply` only after explicit approval. The helper preserves existing nonempty values and atomically writes `/etc/pharos/pharos.env` with its existing owner and mode 0640. It never prints secret values. Retain the payment encryption key across redeploys and include it in protected operator backups; replacing it requires an explicit key-rotation workflow.

The controlled Dynamic receiver is the test-only `pharos/tests/support/qa_integration_receiver.py`, bound to `127.0.0.1:18085`. Board requests require the configured JSON or form token. Its approval endpoint deliberately returns 503 to exercise bounded retry behavior. Use an explicitly named service with the private environment file; verify its health before restarting the shared runtime. This receiver is not a payment provider and must never replace real Stripe credentials or endpoints. Remove the test service only after controlled proof is complete and restore any prior integration settings before doing so.

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
- the automation-facing Pharos release version surface remains `../pharos/VERSION`
- the build-facing Pharos release version surface is `../pharos/Cargo.toml` at `[workspace.package].version`
- those two surfaces must stay synchronized
- `pharos_build_release_version` is an optional explicit override used to bump both surfaces before building
- app packaging now runs through `pharos build app --packaging`, which isolates temporary sqlite and runtime-state paths inside the controller build tree so dynamic app builds do not touch live `/var/lib/pharos` or `/var/state/pharos`
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

If needed, pass an explicit controller-side package path with `-e pharos_deploy_package_src=/path/to/pharos_<version>.deb`. For a server-only update that preserves every deployed app bundle, add `-e pharos_deploy_preserve_existing_apps=true` and deploy changed apps separately with `pharos_app`.

Do not use Ansible `--check` during a Pharos release deployment after the local green gate has approved the exact package or app archive. The release path stages and promotes concrete artifacts, and check mode can spend time on paths that intentionally do not exist until apply.

Expected behavior:

- resolves or accepts a `pharos_*.deb`
- stages it through `roles/ll_repo`
- stops the existing HA monitor and shared runtime before installing it on the target host, keeping post-install migrations isolated from active writers
- by default, installs runtime-packaged app roots and runs migrations only for dynamic app roots owned by the installed Debian package while the shared runtime is stopped. External apps are migrated from their staged updated bundles by pharos_app; runtime deployment never migrates an older external bundle
- when `pharos_deploy_preserve_existing_apps=true`, passes `--path-exclude=/srv/pharos/apps/*` to `dpkg` and skips the runtime role app migration scan so existing deployed apps remain untouched
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
- ensures the host-native `bin/pharos` CLI and helper binaries exist on the controller before packaging any app
- only when `app_id=dev_docs`, reuses the existing host-native Pharos docs builder when the shared narrow `dev_docs` renderer fingerprint matches, and rebuilds it automatically only when the docs crate, docs helper source, app-build entry regions, or relevant docs build scripts changed or the binary is missing; root dependency manifests, lockfiles, and toolchain metadata are explicitly excluded
- only when `app_id=dev_docs`, prebuilds the Rustdoc-backed `dev_docs` artifact through `scripts/build_docs.sh` on the controller before packaging that app
- renders the finalized app root on the controller
- packages it into a tarball under `../pharos/dist/release/app`
- for `app_id=architect`, keeps the `data/models/` directory in the app structure while omitting its model files from the app tarball
- for `app_id=architect`, refreshes the persistent `../pharos/dist/release/app/architect_models.tar.gz` archive from the built app root only when the model source fingerprint changed
- materializes the controller-side archive before deployment so the staged-copy and extract path use the same artifact that will be promoted
- preserves app-owned payload files and ownership-tracked app files in the built artifact, including private archives such as `private/downloads/*.zip` and any generated `.DS_Store` entries still present in the built app root
- for `app_id=architect`, copies the model archive to `/opt/ll/architect_models.tar.gz` only when the remote checksum differs, then expands it into the staged app root before promotion
- stages the bundle via `roles/ll_repo`
- extracts it into a hidden staging directory outside `/srv/pharos/apps`
- when the staged `pharos.app.json` host profile is `dynamic-app`, runs `pharos migrate apply app` on the target against the staged app root using `/etc/pharos/pharos.conf` and the staged `app.conf` backend before the app becomes visible to the shared runtime
- verifies the staged `pharos.app.json` exists and preserves relocatable `app_root` metadata
- promotes the fully prepared staged app root into `/srv/pharos/apps/<app_id>` only after staging verification and migration succeed, so a failed app deploy leaves the previously live app in place
- preserves generated ownership sentinels such as `media/.gitkeep`, which are required by runtime artifact verification
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

Runtime and app deployment stop existing Pharos services before migrations or promotion. The HA monitor stops before the runtime so it cannot restart a writer during the cutover. For coordinated runtime and app updates, include the deployment roles in one play and defer restart handlers until all staged bundles are promoted. Validate the exact release locally and retain pre-deployment data backups before this cutover.

Runtime deployment validates required configuration before stopping services. Debian registers the four package-owned app.conf files as conffiles and retains operator configuration during upgrades. External app staging preserves existing db_* settings before migration so each app keeps its configured backend, namespace and database location. New app defaults remain available for keys without an existing override. Database settings are handled privately and are never logged. A package or app update must not redirect an existing app into another app database.


## Dedicated QA Keycloak service

`keycloak.yml` targets `web0`, which the operator has confirmed is the shared QA/production host. No separate QA inventory group is required. The playbook defaults to plan-only execution and never deploys a Pharos runtime or app. Docker installation reuses `roles/docker_engine`; the isolated `roles/keycloak` owns the Compose stack and `keycloak.service`.

Before apply, provide these host variables (example names must be replaced):

```yml
keycloak_hostname: https://auth.llight.io
keycloak_nginx_hostname: auth.llight.io
keycloak_admin_user: ll-admin
keycloak_bind_address: 127.0.0.1
keycloak_proxy_headers: xforwarded
```

The bind remains loopback. The dedicated `roles/keycloak_nginx` first installs only the new auth HTTP challenge site, issues a trusted certificate using `certbot certonly --webroot`, then copies the certificate chain/key into `/etc/keycloak/tls` for container UID 1000. It does not stop Nginx, edit existing virtual hosts, or open additional firewall ports. After Keycloak is healthy, it enables the auth HTTPS site and gracefully reloads Nginx only after `nginx -t` succeeds. A failed site validation restores that site's previous configuration. PostgreSQL and Keycloak's management port remain unpublished.

The frontend uses the existing public ports 80/443. The upstream is certificate-verified HTTPS on `127.0.0.1:8443`, with SNI `auth.llight.io`. Nginx overwrites forwarded identity headers and Keycloak uses a fixed HTTPS origin. A scoped certbot deploy hook updates only the auth container certificate copies and validates/reloads Nginx; Keycloak reloads certificates every five minutes. No shared runtime or Pharos app is deployed by this playbook.

Both image references are digest-pinned to locally cached inputs: Keycloak 26.8.1 and PostgreSQL 16 Alpine. Registry pulls are disabled. Transfer reviewed local Docker image archives to the target and optionally list their absolute target paths in `keycloak_image_archives`; ensure the pinned references resolve locally after loading. Missing pinned images stop installation rather than falling back to a registry. Images must match the target architecture. Docker Engine package installation uses the existing role and its official Docker apt repository.

Run from `ops/` against the confirmed shared host:

```bash
apb keycloak.yml -l web0 --check
apb keycloak.yml -l web0 -e keycloak_apply=true
```

Review the plan before the opt-in apply. `--check` always remains non-mutating, even with the apply variable. Vault credentials and DNS/image prerequisites are required for the actual installation. Installation waits for database and Keycloak readiness; a failure prevents a successful service start.

Service management on the target:

```bash
sudo systemctl status keycloak.service
sudo systemctl stop keycloak.service
sudo systemctl start keycloak.service
sudo systemctl restart keycloak.service
sudo journalctl -u keycloak.service
sudo docker compose --project-name keycloak --file /opt/keycloak/compose.yml logs --tail 100
```

Default container memory limits are 1536 MiB for Keycloak and 512 MiB for PostgreSQL, leaving capacity for the existing shared runtime. Override `keycloak_memory_limit` and `keycloak_postgres_memory_limit` deliberately after checking host capacity.

The role avoids a redundant restart when it has just started the service with the final configuration; configuration changes restart an already active service. The systemd unit is enabled at boot. Compose also restarts containers after crashes. Stopping the service removes containers and networks while retaining the named PostgreSQL volume; starting recreates containers using that same database. Do not use `down --volumes`, remove the volume, or change the Compose project name. Reapplying the role defaults to starting and enabling the service; set `keycloak_service_state: stopped` or `keycloak_service_enabled: false` deliberately when required.

Initial admin username comes from `keycloak_admin_user`: `ll-admin` on the shared host (the role default remains `qa-admin`). The Vault-provided bootstrap admin password and database password are retained in root-only `/opt/keycloak/credentials.json`; retrieve them privately with `sudo` on the target. Separate root-only environment files limit which credentials each container receives. Never paste these values into tickets, logs, or tracked variables. Existing credentials are retained on rerun; installation refuses to generate replacement credentials when a retained database volume already exists. Replacing an environment password does not rotate credentials already stored in PostgreSQL or Keycloak. Bootstrap administration is temporary: create a named operator admin and remove the temporary account after first setup, following the Keycloak admin workflow.

Before acceptance, verify HTTPS discovery and readiness twice, create a test realm/account, stop/start the service and confirm that account survives. A host reboot test must be scheduled explicitly to avoid interrupting shared QA services. Back up PostgreSQL with `pg_dump` into protected storage and prove restore into an isolated database before claiming backup acceptance. No reboot or backup acceptance is implied by enabling the unit.

The Docker role now uses idempotent built-in download/copy modules for its official signing key and apt source instead of shell pipelines, and rejects unsupported distributions before package changes. The Keycloak health probe uses HTTP only on its unpublished management port; browser traffic requires HTTPS.

This role installs the identity server only. Realm/client/policy provisioning, private test mailbox routing, external Pharos HTTPS configuration and Stripe sandbox end-to-end validation are separate acceptance steps. Until Brevo delivery is restored, captured email proves activation flow but not real mailbox delivery.


Local role validation uses the existing Ansible Python environment (Jinja2 and PyYAML already installed), the cached pinned images and Docker Compose. It creates a uniquely named disposable project and test volume, checks certificate-validated HTTPS discovery twice, creates an account through the admin API, and confirms persistence after Compose down/up. The self-signed certificate is trusted only by that test and removed during cleanup; it is not suitable for external acceptance.

```bash
ansible-lint --offline keycloak.yml roles/keycloak roles/docker_engine
KEYCLOAK_DOCKER_TEST=1 python -m unittest discover -s tests -p test_keycloak_role.py -v
python3 bin/check_features_sync.py
```


Store two distinct passwords in encrypted `group_vars/prod_web/vault.yml` as `keycloak_admin_password` and `keycloak_database_password`. Use 32–128 random ASCII letters and digits per password, without dollar signs or newlines so Compose environment parsing cannot alter their values. The canonical nonsecret admin username is `keycloak_admin_user` (default `qa-admin`). The shared host maps the passwords to `vault.keycloak.admin_pass` and `vault.keycloak.db_pass` in `group_vars/prod_web/main.yml`. The role neither generates replacement passwords nor rotates existing database/admin credentials on rerun: mismatches between Vault and the retained installation block apply.

Docker may be installed independently while the operator prepares Vault credentials and the HTTPS origin:

```bash
apb keycloak.yml -l web0 --check -e keycloak_docker_only=true
apb keycloak.yml -l web0 -e keycloak_apply=true -e keycloak_docker_only=true
```

The Docker-only path skips Keycloak configuration and startup. It requires no Keycloak passwords and does not restart nginx or Pharos. Run the full playbook without the Docker-only flag once the remaining inputs are ready.


### Adding only the authentication DNS record through Spaceship

DNS is managed by `tf/main.tf` using the existing `spaceship_dns_records.root` resource. `auth.llight.io` points to the existing reserved public IP, alongside the existing root/www/pharos A records and MX records. Do not add a second DNS resource for the same zone or use the broad Terraform bootstrap apply for this change.

For this narrowly scoped DNS addition, create a saved plan targeting `spaceship_dns_records.root` with the existing local providers and GCP credentials, save its JSON privately, and run `python3 bin/check_keycloak_dns_plan.py <plan.json> --address <existing-server-ip>`. The guard rejects any existing-record removal/modification, server changes, resource replacement, or addition other than the single auth A record. JSON and plan files can include sensitive Terraform variables: keep them owner-only under ignored `dist/`. Review the accepted plan and apply that exact saved plan; do not use auto-approve. After apply, refresh the targeted plan and compare the live records against the pre-apply snapshot. This exceptional target prevents unrelated VM image drift from entering the DNS apply.

Operator authorization covers adding the auth tenant on the shared host. Existing Nginx site contents should be hashed before and after the rollout, and their HTTPS pages checked on both sides of each service transition. Do not reboot the shared host to prove boot persistence without a separately scheduled window. The server installation is complete only after public certificate validation, expected OIDC issuer, Vault-backed administrator login and Keycloak service start/stop persistence all pass.


`tests/check_keycloak_live.py` runs on the shared host as root using the retained private credentials. It never prints passwords or tokens and always verifies the public certificate. Its `inspect` action checks issuer and the configured administrator; `create` makes a uniquely named disposable acceptance realm/account, `verify` proves persistence after a controlled `keycloak.service` stop/start, and `cleanup` removes only that owned realm/state. Pass `--admin-user ll-admin` for this host. Never reboot or restart Nginx/Pharos for this identity-service persistence check.


### Subscription application integration

`keycloak_application.yml` configures the external `pharos` realm on `auth.llight.io`. Its public browser client uses authorization code flow with S256 PKCE and the exact local review callback `http://localhost:7524/__pharos/keycloak/callback`; logout returns to `http://localhost:7524/accounts/login/`. Its confidential `pharos-provisioner` client has user-management roles only in this application realm. Its independent credential is stored as `vault.keycloak.provisioner_secret`. The application receives no master-realm administrator password.

The `keycloak_application_realm_source` variable identifies the reviewed local Pharos realm JSON. For the feature worktree, pass its absolute `containers/keycloak/pharos-realm.json` path; the normal default is the sibling `pharos` checkout. Plan first, then opt in with `keycloak_application_apply=true`. The helper creates a missing realm once, updates only declared settings/clients on rerun, preserves accounts and signing keys, and refuses an unplanned provisioner-secret rotation or missing-client recreation.

While Brevo remains unavailable, `keycloak-capture-forward.service` listens only on the existing private Docker gateway. It accepts only that Docker subnet and forwards capture SMTP to loopback SSH tunnel endpoints: private port 21126 to 21125 for disposable acceptance, and private port 21226 to 21225 for manual review. It is bounded to eight concurrent connections per endpoint and 512 KiB per SMTP connection, runs as a dynamic unprivileged user, and exposes no public SMTP or mailbox listener. It has no real-relay configuration. Forwarding fails visibly while the local SSH tunnel/inbox is absent; native purchase delivery retry remains available.

Local acceptance supplies SSH reverse forwarding from those remote loopback endpoints to the isolated local capture listeners. Manual review uses a separate local portal/inbox at ports 7524/8225 and preserves the original 7324/8025 environment. Actual Stripe sandbox requests use test credentials, and `local=false` enforces the external issuer transport profile. This does not deploy or replace the shared Pharos runtime on Linux.

`keycloak_application_external_config` optionally exports owner-only diagnostic administration/provisioner settings into an explicitly supplied local ignored file. Use it only for acceptance and keep it out of logs and source control. The native service configuration receives only the realm provisioner secret, its own policy/management credentials and Stripe test credentials.

Server resilience acceptance is complete by the operator's instruction; the acceptance report distinguishes that decision from agent-observed checks.

The authentication tenant logs only method, path, status and timing; query strings, action tokens, cookies and request bodies are excluded from its dedicated access log.


## Native subscription service on QA

The standalone access service runs at https://access.llight.io on the shared QA/production machine. It is independent of the shared Pharos runtime and uses Stripe sandbox with real Keycloak SMTP. It does not require live Stripe credentials or actual sales. Clippy is a local build lint tool; it is not a server prerequisite. The exact Linux artifact must pass local compile/check, targeted tests and deployment-shaped authenticated validation before installation. Native Rust source changes retain the repository's lint requirements; no additional target-server compiler or lint installation is needed.

The pharos_access.yml playbook defaults to a plan. Its role validates binary and browser hashes against the approved local gate, stages an immutable release, creates an independent pharos-access-qa realm, and enables pharos-access.service. The application binds 127.0.0.1:7624 behind its dedicated Nginx tenant. Certbot issues the access certificate through a dedicated webroot without stopping Nginx; the renewal hook validates and reloads Nginx. Existing runtime, capture realm and other Nginx sites are preserved.

The access DNS A record is managed by tf/main.tf in the existing Spaceship zone resource. Use a targeted saved plan and bin/check_keycloak_dns_plan.py with --name access --address 34.169.129.168. The guard permits only that single addition and preserves every existing record; never include unrelated server drift in the apply. Review and apply the exact accepted saved plan, then require a targeted no-change plan.

Provide an owner-only ignored extra-vars JSON with pharos_access_binary, pharos_access_gate, pharos_access_web_root, pharos_access_settings, pharos_access_environment and pharos_access_realm_definition. The private environment keys are PHAROS_PROVISIONER_SECRET, PHAROS_ACCESS_AUTHORIZATION_SECRET, PHAROS_ACCESS_MANAGEMENT_SECRET, PHAROS_STRIPE_SECRET and PHAROS_STRIPE_WEBHOOK_SECRET. The role accepts test-mode Stripe keys only. Register the sandbox endpoint at https://access.llight.io/webhooks/stripe for Checkout completion/asynchronous results, charge refunds and dispute creation. Store its real signing secret privately. Enable the endpoint after HTTPS health passes, then verify genuine Stripe sandbox events against the deployed purchase state.

Use the realm import with exact HTTPS callback and logout URLs at access.llight.io, a separate provisioner secret and authenticated STARTTLS SMTP. The master administrator password remains in the existing Vault variable and is used only for realm provisioning. Stable generated QA application credentials are retained in dist/qa-access-private/deployment.json with owner-only permissions; preserve this file or move its values into operator-controlled Vault storage before replacing the workspace.

```sh
apb pharos_access.yml -l web0 -t pharos_access
apb pharos_access.yml -l web0 -t pharos_access -e @dist/qa-access-private/deployment.json -e pharos_access_apply=true
```

The service runs as pharos-access with a read-only system, private temporary directory, bounded memory/tasks and no capabilities. Private environment credentials are in /etc/pharos-access/service.env, host settings in /etc/pharos-access/service.json, and durable purchases in /var/lib/pharos-access/subscriptions.sqlite3. Releases live under /opt/pharos-access/releases with a current symlink. Promotion checks readiness twice and restores the previous binary link, unit and private configuration on failure when available. Service lifecycle uses systemctl start, stop or restart pharos-access.service; enablement persists reboots. Inspect safe diagnostics with journalctl -u pharos-access.service.

QA must verify real SMTP configuration, account provisioning, submission to the relay, durable delivery failure/retry handling, OIDC and policy behavior. An external Brevo rejection or bounce after submission is recorded separately and does not fail application QA when service behavior is correct. Successful SMTP submission does not claim delivery to the real inbox. Keep activation and signed login covered through a private capture realm when external delivery is unavailable; do not replace the real SMTP settings of the persistent QA realm merely to run automation. No live-money transaction is required for this sandbox deployment, and the deployment does not merge main.
