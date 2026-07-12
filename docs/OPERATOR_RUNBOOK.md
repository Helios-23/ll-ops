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
- group vars: `group_vars/all`, `group_vars/prod`, `group_vars/prod_ai`, `group_vars/prod_web`
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

Web server baseline:

```bash
apb setup_epytype.yml -l web0
```

Narrow to role/task areas for incremental work:

```bash
apb setup_epytype.yml -l repo0 -t forgejo
apb setup_epytype.yml -l repo0 -t forgejo_pull
apb setup_epytype.yml -l repo0 -t forgejo_users
apb setup_epytype.yml -l gex0 -t ai_rig
apb setup_epytype.yml -l web0 -t lantern
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

The active migration path moves Lantern onto `web0` as its own public web host. Its public entrypoint remains `https://lantern.epytype.org`. During transition, `gex0` may still serve the live site until DNS is cut over.

Common command:

```bash
apb setup_epytype.yml -l web0 -t lantern
```

The packaged Lantern runtime defaults to `socket_path=/run/lantern/lantern.sock`, and `prod_web` enables `lantern_use_socket: true`, so nginx proxies to that Unix socket there. The packaged systemd unit creates `/run/lantern` with mode `0750`, assigns it to group `www-data`, and the Lantern runtime sets `/run/lantern/lantern.sock` to group `www-data` with mode `0660` so nginx can connect without making the socket world-accessible. If `lantern_use_socket` is disabled, the role falls back to TCP proxying at `127.0.0.1:7323`.

Verification:

- `curl -I https://lantern.epytype.org`
- `curl https://lantern.epytype.org/api/graph/health` (or another app health endpoint you expect to be live) to confirm upstream health still works through nginx
- confirm `/etc/nginx/sites-available/lantern.epytype.org.conf` and `/etc/nginx/sites-enabled/lantern.epytype.org.conf` exist
- confirm `/var/log/nginx/lantern.access.log` and `/var/log/nginx/lantern.error.log` are being written
- in socket mode, confirm `test -S /run/lantern/lantern.sock` on `web0`
- confirm `stat -c '%A %U %G %n' /run/lantern /run/lantern/lantern.sock` reports `/run/lantern` as mode `0750` and group `www-data`, and `lantern.sock` as mode `0660` and group `www-data`
- if DNS has not been cut over yet, run the same checks directly on `web0` before changing the public record

### 8b. Build the Lantern binaries and release artifacts

`build.yml` is the generic product-build entry in `ops/`. Today it contains both `roles/lantern_build` (real build) and `roles/epytype_build` (placeholder for when the Epytype cross-build pipeline is wired up). Select a single role's tasks with `-t <role>`; omit `-t` to run every role.

Run this from `ops/` on the controller with Lantern and Epytype repos as sibling checkouts, and Docker available:

```bash
apb build.yml -t lantern_build
```

Build a single architecture (skip the other six):

```bash
apb build.yml -t lantern_build -e target=linux-aarch64-gnu
```

Run both roles (Epytype side fails today because its pipeline isn't implemented yet):

```bash
apb build.yml
```

Target matrix for `lantern_build`:

| Target | Architecture | Libc / Runtime | Compatible distros / OS |
| --- | --- | --- | --- |
| `linux-x86_64-gnu` | x86_64 | glibc | Debian, Ubuntu, Red Hat, Fedora, CentOS, Rocky, Alma, SUSE, Arch |
| `linux-x86_64-musl` | x86_64 | musl | Alpine Linux |
| `linux-aarch64-gnu` | ARM64 (AArch64) | glibc | Debian/Ubuntu ARM64, Fedora ARM, RHEL ARM, Rocky ARM |
| `linux-riscv64-gnu` | RISC-V 64-bit | glibc | Debian RISCV64, Fedora RISCV64, Ubuntu RISCV64 |
| `macos-universal` | x86_64 + ARM64 | macOS | macOS 11+ (Intel + Apple Silicon) |
| `windows-x86_64-msvc` | x86_64 | Windows (MSVC) | Windows 10/11 x86_64, Windows Server |
| `windows-arm64-msvc` | ARM64 | Windows (MSVC) | Windows 11 ARM64, Windows Server ARM |

Default: `all` (builds all seven). Pass `-e target=<name>` to build a single target.

What `lantern_build` does:

- runs `docker compose run --rm` for each selected target using `lantern/cross/docker/docker-compose.yml`
- each container: compiles with zig, validates the binary, runs `package-lantern-artifacts` which produces tar.gz/zip/checksums/sigs and a linux-gnu `.deb` (when applicable) into `dist/packages/`
- consumes `../epytype/dist/binaries` for included Epytype runtime binaries via the epytype cross scripts
- includes only `atlas_studio` and `graph_studio` in the package payload

Verification (per-run scoped):

- captures the run-start timestamp at the top of the role, then lists release artifacts in `dist/packages` whose `mtime` is at-or-after that timestamp
- this catches both fresh writes and in-place overwrites, so a single-target run against an already-populated `dist/packages` (the normal case) still shows only the artifacts freshly laid down by this invocation
- an `all` invocation shows every target's artifacts this run produced
- accepts any release artifact matching `*.deb`, `*.rpm`, `*.apk`, `*.tar.gz`, `*.tgz`, `*.msix`, or `*.zip`; sidecars (`.sha256`, `.asc`, `.manifest.json`, `.zst`) are intentionally excluded so verification works for every target, including non-deb builds such as `linux-x86_64-musl`, `macos-universal`, `windows-x86_64-msvc`, and `windows-arm64-msvc`
- fails the playbook if no release artifact was produced

What `epytype_build` does today:

- prints a placeholder notice explaining the Epytype cross-build pipeline is not yet wired up
- runs the same validation, snapshot, and verify scaffolding `lantern_build` uses, so wiring the real build steps later is mechanical
- calls without `-t epytype_build` won't trigger it; calling it today will fail at the verify step because no artifact lands in `dist/packages`

### 8c. Deploy the Lantern runtime package

Use this after building a `.deb` if you want to install it on `web0`:

```bash
apb deploy.yml -t lantern_runtime -l web0
```

What it does:

- resolves the newest `lantern_*.deb` from `lantern/dist/packages` on the controller when no package path is passed
- copies the `.deb` to `web0`
- installs it with `dpkg` and repairs dependencies with `apt`
- restarts `lantern.service` and `lantern-ha.service` so packaged runtime changes (including the `/run/lantern` directory ownership/mode and `lantern.sock` group-access contract for nginx) are picked up cleanly

The build step expects `../epytype/dist/binaries` to contain the matching `epytype` and `epm` release binaries.

### 8d. Deploy a Lantern app bundle

Use this when you want to sync one Lantern app bundle from `lantern/apps/` into the shared runtime apps tree on `web0`:

```bash
apb deploy.yml -t lantern_app -l web0 -e lantern_app_id=ucal
```

What it does:

- refreshes the Lantern repo on the controller with `git clone` or `git pull`
- reads the controller git SHA after the repo sync completes
- creates `/opt/release/lantern/app/<app_id>-<YYYYMMDD-HHMM>-<8-char-sha>-<bundle-fingerprint-short>.tar.gz` on the controller
- rebuilds that archive only when the app bundle contents change
- keeps the last deployed app archive marker on `web0` and copies/extracts whenever the bundle changes or the controller archive basename differs from that marker
- stores deployed archives under `/srv/lantern/apps/<app_id>/.archives/` for rollback
- updates `/srv/lantern/apps/<app_id>/.deployed-archive` only after extraction succeeds
- extracts newer archives into `/srv/lantern/apps/<app_id>` with `lantern:lantern` ownership

Supported app ids today:

- `atlas_studio`
- `graph_studio`
- `ucal`

The archive is built on the controller under `/opt/release/lantern/app` only when the bundle changes, and deployment proceeds whenever the bundle changes or that controller archive basename differs from the deployed archive marker on `web0`. The target keeps the deployed archive copy under `/srv/lantern/apps/<app_id>/.archives/` and only updates the deployed marker after extraction succeeds.

The Lantern `.deb` deploy path uses `dpkg -i` followed by `apt-get -f install -y` so a freshly built package is applied even when the package version has not changed. After install, the target keeps the current staged `.deb` and removes older `lantern_*.deb` files from the staging directory so the host does not accumulate stale packages.

The package version now includes the Lantern git commit suffix as `+git<8-char-sha>`, and appends a short dirty-tree fingerprint when the Lantern checkout has uncommitted changes, so each release build has an explicit source revision marker even before commit time.

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
7. commit release prep, create tag, and push `HEAD:release` to the primary remote
8. push the tag to GitHub to trigger the `release.yml` GHA workflow

Verification:

- inspect the generated version and tag before push
- confirm release checks passed
- verify git push to GitHub succeeded
- confirm the tag push triggered the `release.yml` GitHub Actions workflow at `https://github.com/Epytype/<repo>/actions`

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
