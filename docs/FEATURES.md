# Ops Features

Compact index of the playbooks, roles, and tags in `ops/`.

Use this as the quick command map. The **Complete Tag Index** and **Role Notes** sections below are the authoritative inventory checked by `ops/bin/check_features_sync.py`.

`inventory/logicallight` is configured in `ops/ansible.cfg`, so the examples below omit `-i` unless you are intentionally overriding the default inventory.

## Playbook Quick Map

| Playbook | Scope | Flow | Main tags | Focus tags |
| --- | --- | --- | --- | --- |
| `setup_pharos.yml` | `web0` | baseline the public web host, nginx, TLS, and the Pharos edge vhost | `web_server` | `harden`, `nginx`, `certbot_tls`, `pharos`, `pharos_nginx` |
| `deploy.yml` | `web0` | deploy either the Pharos runtime package or a single Pharos app bundle | `pharos_runtime`, `pharos_app` | `pharos_runtime`, `pharos_app` |
| `build.yml` | `localhost` | bump `../pharos/VERSION` from the ops-side build version when newer, prebuild the packaged `dev_docs` artifact on the controller, and build Pharos release artifacts via Docker Compose, optionally for one target | `pharos_build` | `pharos_build` |
| `admin.yml` | selected hosts with `-l` required | run generic admin tasks and optional Tailscale management on a limited host set | `admin` | `update_reboot`, `tailscale`, `tailscale_machine`, `tailscale_policy` |
| `terraform.yml` | `localhost` | decrypt vaulted Spaceship credentials, render Terraform auto tfvars for Spaceship and GCP, enable `compute.googleapis.com` and bootstrap the GCP VPC/subnet/firewall/IP/VM when the Pharos public IP is not yet in state, run the full Terraform plan/apply, update `inventory/logicallight` for `web0`, manage `pharos.llight.io` DNS in Spaceship, and print the resulting infrastructure summary | `terraform` | none |
| `keymaster.yml` | selected hosts | run key and certificate operations via `roles/keymaster`; most paths require explicit tags | `kymstr` | `install`, `encrypt`, `gen-ssh`, `ssh-gen`, `gen-csr`, `check-csr`, `ssh-auth`, `ssh-auth-review`, `ssh-key`, `ssh-key-report`, `cert`, `mysql`, `never` |

## Examples

### `setup_pharos.yml`

```bash
apb setup_pharos.yml -l web0
apb setup_pharos.yml -l web0 -t pharos
apb setup_pharos.yml -l web0 -t pharos_nginx
```

### `deploy.yml`

```bash
apb deploy.yml -l web0 -t pharos_runtime
apb deploy.yml -l web0 -t pharos_app -e app_id=ucal
```

### `build.yml`

```bash
apb build.yml -t pharos_build
apb build.yml -t pharos_build -e target=linux-aarch64-gnu
apb build.yml -t pharos_build -e pharos_build_release_version=0.7.24
```

### `admin.yml`

```bash
apb admin.yml -l web0
apb admin.yml -l web0 -t update_reboot
apb admin.yml -l web0 -t tailscale_machine
apb admin.yml -l web0 -t tailscale_policy
```

### `terraform.yml`

```bash
apb terraform.yml -t terraform
```

### `keymaster.yml`

```bash
apb keymaster.yml -l web0 -t ssh-auth
apb keymaster.yml -l web0 -t gen-csr
apb keymaster.yml -l web0 -t cert
```

## Role Task Areas

### `roles/keymaster`

| Task area | Tags | Purpose | Notes |
| --- | --- | --- | --- |
| dependency bootstrap | `install`, `never` | install `pyOpenSSL` where needed | intentionally opt-in |
| vault encryption | `encrypt`, `never` | encrypt local certificate material with `ansible-vault` | controller-side only |
| SSH key generation | `gen-ssh`, `ssh-gen`, `never` | generate local SSH keypairs from configured auth data | controller-side only |
| CSR generation and review | `gen-csr`, `check-csr`, `never` | build private keys and CSRs, then inspect subject fields | controller-side only |
| SSH authorization rollout | `ssh-auth`, `never` | remove unauthorized keys and install approved keys | runs on selected hosts |
| access review reporting | `ssh-auth-review`, `never` | produce a local auth report | writes local report files |
| key fingerprint reporting | `ssh-key-report`, `never` | inspect deployed `authorized_keys` fingerprints | writes local report files |
| automation key install | `ssh-key`, `never` | place automation keys on remote hosts | verify template paths before use |
| certificate deployment | `cert`, `never` | copy certs and private keys to remote SSL paths | use only after local material is ready |
| MySQL helper tasks | `mysql`, `never` | run the MySQL-specific keymaster include | see `roles/keymaster/tasks/mysql.yml` |

## Complete Tag Index

### Play-level tags

| Tags |
| --- |
| `admin`, `kymstr`, `pharos_app`, `pharos_runtime`, `terraform`, `web_server` |

### Role-level tags

| Tags |
| --- |
| `certbot_tls`, `harden`, `nginx`, `pharos`, `pharos_app`, `pharos_build`, `pharos_nginx`, `pharos_runtime`, `tailscale`, `tailscale_machine`, `tailscale_policy` |

### Task-level tags

| Tags |
| --- |
| `always`, `cert`, `check-csr`, `encrypt`, `fail2ban`, `fail2ban_sshd_invalid_user`, `gen-csr`, `gen-ssh`, `install`, `ipv4-forward`, `mysql`, `never`, `reverse_proxy_fail2ban`, `ssh-auth`, `ssh-auth-review`, `ssh-gen`, `ssh-key`, `ssh-key-report`, `update_reboot` |

## Role Notes

| Role | Main tags | Extra tags / notes |
| --- | --- | --- |
| `roles/admin` | none | task tag: `update_reboot` |
| `roles/certbot_tls` | `certbot_tls` | ACME/TLS issuance and renewal support for nginx-hosted services |
| `roles/docker_engine` | none | installs Docker Engine and Compose prerequisites on build-capable hosts |
| `roles/harden` | `harden` | extra tags: `fail2ban`, `fail2ban_sshd_invalid_user`, `ipv4-forward`, `reverse_proxy_fail2ban` |
| `roles/keymaster` | none | key and certificate workflows are documented above under Role Task Areas |
| `roles/ll_repo` | none | stages controller-built artifacts under `/opt/ll/<type>` and supports pruning retained archives |
| `roles/nginx` | `nginx` | base nginx installation and service management |
| `roles/pharos` | `pharos` | deploys the `pharos.llight.io` nginx vhost, obtains the TLS cert with standalone certbot while nginx is temporarily stopped for initial issuance, and maintains certbot renewal; extra tag: `pharos_nginx` |
| `roles/pharos_app_deploy` | `pharos_app` | builds a finalized app root on the controller with `pharos build app --packaging`, extracts it into `/srv/pharos/apps/<app_id>`, and prunes old staged bundles |
| `roles/pharos_build` | `pharos_build` | bumps `../pharos/VERSION` when `pharos_build_release_version` is newer, syncs the Doxygen project number, prebuilds `dev_docs` on the controller for Debian packaging, and builds release artifacts through `pharos/cross/docker`; default target is `all`, override with `-e target=<name>` |
| `roles/pharos_deploy` | `pharos_runtime` | resolves the newest staged `pharos_*.deb`, installs it on the target host, restarts services, and prunes older runtime packages |
| `roles/tailscale_admin` | `tailscale`, `tailscale_machine`, `tailscale_policy` | `tailscale_machine` manages host enrollment/runtime settings; `tailscale_policy` pushes tailnet policy |

## Agent Guard

For AI-agent edits inside `ops/`:

- `ops/AGENTS.md` tells agents to treat `ops/docs/FEATURES.md`, `ops/docs/OPERATOR_RUNBOOK.md`, and `ops/docs/README.md` as part of the `ops` change surface
- `ops/bin/check_features_sync.py` checks that the **Complete Tag Index** matches the tags present in `ops/*.yml` and `ops/roles/**/*.yml`
- the same checker also verifies that all `ops` playbooks and role directories are explicitly listed in `FEATURES.md`
- agents working in `ops/` should run the checker before finishing their turn
