# Ops Features

Compact index of the playbooks, roles, and tags in `ops/`.

Use this as the quick command map. The **Complete Tag Index** and **Role Notes** sections below are the authoritative inventory checked by `ops/bin/check_features_sync.py`.

`inventory/logicallight` is configured in `ops/ansible.cfg`, so the examples below omit `-i` unless you are intentionally overriding the default inventory.

## Playbook Quick Map

| Playbook | Scope | Flow | Main tags | Focus tags |
| --- | --- | --- | --- | --- |
| `setup_pharos.yml` | `web0` | baseline the public web host, nginx, TLS, and the Pharos edge vhost | `web_server` | `harden`, `nginx`, `certbot_tls`, `pharos`, `pharos_nginx` |
| `deploy.yml` | `web0` | deploy either the Pharos runtime package or a single Pharos app bundle | `pharos_runtime`, `pharos_app` | `pharos_runtime`, `pharos_app` |
| `build.yml` | `localhost` | bump `../pharos/VERSION` from the ops-side build version when newer and build Pharos release artifacts via Docker Compose, optionally for one target; the default all-target build currently skips `macos-universal` because the current cross image is broken for that target | `pharos_build` | `pharos_build` |
| `admin.yml` | selected hosts with `-l` required | run generic admin tasks and optional Tailscale management on a limited host set | `admin` | `update_reboot`, `tailscale`, `tailscale_machine`, `tailscale_policy` |
| `terraform.yml` | `localhost` | decrypt vaulted Spaceship credentials, render Terraform auto tfvars for Spaceship and GCP, plan the GCP VPC/subnet/firewall/IP/VM bootstrap when the Pharos public IP is not yet in state plus all other Terraform changes, update `inventory/logicallight` for `web0`, manage Spaceship DNS in `tf/main.tf` (configured MX records plus A records for the root domain, `www`, and `pharos` all pointing at the Pharos public IP), and print the resulting infrastructure summary; apply runs only when `terraform_apply=true` is passed explicitly; core GCP resources in `tf/main.tf` (network, subnet, firewall, reserved IP, instance) carry `lifecycle { prevent_destroy = true }` so an apply can never delete and recreate existing infrastructure | `terraform` | none |
| `keymaster.yml` | selected hosts | run key and certificate operations via `roles/keymaster`; most paths require explicit tags | `kymstr` | `install`, `encrypt`, `gen-ssh`, `ssh-gen`, `gen-csr`, `check-csr`, `ssh-auth`, `ssh-auth-review`, `ssh-key`, `ssh-key-report`, `cert`, `mysql`, `never` |
| `cloud_bootstrap.yml` | `localhost` | bootstrap cloud provider service accounts, roles, and credentials for Terraform; supports GCP, AWS, and Azure via `cloud_bootstrap_provider` | `cloud_bootstrap` | `cloud_bootstrap`, `cloud_gcp`, `cloud_aws`, `cloud_azure` |

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
apb terraform.yml -t terraform -e terraform_apply=true
```

### `keymaster.yml`

```bash
apb keymaster.yml -l web0 -t ssh-auth
apb keymaster.yml -l web0 -t gen-csr
apb keymaster.yml -l web0 -t cert
```

### `cloud_bootstrap.yml`

```bash
apb cloud_bootstrap.yml -e cloud_bootstrap_provider=gcp
apb cloud_bootstrap.yml -e cloud_bootstrap_provider=aws
apb cloud_bootstrap.yml -e cloud_bootstrap_provider=azure
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

### `roles/cloud_bootstrap`

| Task area | Tags | Purpose | Notes |
| --- | --- | --- | --- |
| provider validation | `cloud_bootstrap` | validate `cloud_bootstrap_provider` and required variables | |
| GCP API enablement | `cloud_bootstrap`, `cloud_gcp` | enable foundational GCP APIs (cloudresourcemanager, serviceusage, compute) | idempotent via `google.cloud.gcp_serviceusage_service` |
| GCP org policy override | `cloud_bootstrap`, `cloud_gcp` | disable org policy blocking SA key creation | command-based, only when key creation is needed |
| GCP service account | `cloud_bootstrap`, `cloud_gcp` | create Terraform service account | idempotent via `google.cloud.gcp_iam_service_account` |
| GCP IAM role assignment | `cloud_bootstrap`, `cloud_gcp` | assign required roles to the service account | idempotent via `google.cloud.gcp_resourcemanager_project_iam_member` |
| GCP key generation | `cloud_bootstrap`, `cloud_gcp` | generate JSON key for Terraform | only when local key file is missing |
| AWS IAM user and policies | `cloud_bootstrap`, `cloud_aws` | create IAM user, attach managed policies, generate access key | uses `amazon.aws.iam_user` and `amazon.aws.iam_user_policy_attachment` |
| Azure service principal | `cloud_bootstrap`, `cloud_azure` | create service principal, assign role, save credentials | uses `azure.azcollection.azure_rm_resourcegroup` |

## Complete Tag Index

### Play-level tags

| Tags |
| --- |
| `admin`, `cloud_bootstrap`, `kymstr`, `pharos_app`, `pharos_runtime`, `terraform`, `web_server` |

### Role-level tags

| Tags |
| --- |
| `certbot_tls`, `cloud_bootstrap`, `cloud_gcp`, `cloud_aws`, `cloud_azure`, `fail2ban`, `harden`, `nginx`, `pharos`, `pharos_app`, `pharos_build`, `pharos_nginx`, `pharos_runtime`, `tailscale`, `tailscale_machine`, `tailscale_policy` |

### Task-level tags

| Tags |
| --- |
| `always`, `cert`, `check-csr`, `cloud_aws`, `cloud_azure`, `cloud_bootstrap`, `cloud_gcp`, `encrypt`, `fail2ban`, `fail2ban_sshd_invalid_user`, `gen-csr`, `gen-ssh`, `install`, `ipv4-forward`, `mysql`, `never`, `pharos_domains`, `port_knock`, `reverse_proxy_fail2ban`, `ssh-auth`, `ssh-auth-review`, `ssh-gen`, `ssh-key`, `ssh-key-report`, `update_reboot` |

## Role Notes

| Role | Main tags | Extra tags / notes |
| --- | --- | --- |
| `roles/admin` | none | task tag: `update_reboot` |
| `roles/cloud_bootstrap` | `cloud_bootstrap` | extra tags: `cloud_gcp`, `cloud_aws`, `cloud_azure`; provider-specific bootstrap for Terraform service accounts and credentials; controller-side only |
| `roles/certbot_tls` | `certbot_tls` | ACME/TLS issuance and renewal support for nginx-hosted services |
| `roles/docker_engine` | none | installs Docker Engine and Compose prerequisites on build-capable hosts |
| `roles/fail2ban` | `fail2ban` | extra tags: `fail2ban_sshd_invalid_user`, `reverse_proxy_fail2ban`; configure jails, filters, and helper scripts; run immediately after `harden` |
| `roles/harden` | `harden` | extra tags: `ipv4-forward`, `port_knock` |
| `roles/keymaster` | none | key and certificate workflows are documented above under Role Task Areas |
| `roles/ll_repo` | none | stages controller-built artifacts under `/opt/ll/<type>` and supports pruning retained archives |
| `roles/nginx` | `nginx` | base nginx installation and service management |
| `roles/pharos` | `pharos` | deploys an nginx vhost with a TLS server block per entry in `domain_list` (each redirecting `/` to its `root_url`, canonically redirecting the bare root_url path to its slash-terminated form when needed, and using its own certificate), obtains a standalone certbot cert for each `domain_list` entry missing one while nginx is temporarily stopped, and maintains certbot renewal; extra tags: `pharos_nginx`, `pharos_domains` |
| `roles/pharos_app_deploy` | `pharos_app` | builds a finalized app root on the controller with `pharos build app --packaging`, ensures the host-native `bin/pharos` CLI exists for app packaging, runs the `dev_docs` renderer fingerprint and prebuild path only when `app_id=dev_docs`, extracts the bundle into `/srv/pharos/apps/<app_id>`, runs `pharos migrate apply app` on the target only when the deployed manifest host profile is `dynamic-app` using the deployed `app.conf` backend and `/etc/pharos/pharos.conf`, and prunes old staged bundles |
| `roles/pharos_build` | `pharos_build` | bumps `../pharos/VERSION` when `pharos_build_release_version` is newer and builds release artifacts through `pharos/cross/docker`; default target is `all`, override with `-e target=<name>`; `macos-universal` is currently blocked explicitly because the shipped cross-image `libpq.a` for that target contains ELF objects and fails to link as a macOS archive |
| `roles/pharos_deploy` | `pharos_runtime` | resolves the newest staged `pharos_*.deb`, installs it on the target host, applies bundled dynamic-app migrations for packaged apps already installed under `/srv/pharos/apps` before restart, restarts services, and prunes older runtime packages |
| `roles/tailscale_admin` | `tailscale`, `tailscale_machine`, `tailscale_policy` | `tailscale_machine` manages host enrollment/runtime settings; `tailscale_policy` pushes tailnet policy |

## Agent Guard

For AI-agent edits inside `ops/`:

- `ops/AGENTS.md` tells agents to treat `ops/docs/FEATURES.md`, `ops/docs/OPERATOR_RUNBOOK.md`, and `ops/docs/README.md` as part of the `ops` change surface
- `ops/bin/check_features_sync.py` checks that the **Complete Tag Index** matches the tags present in `ops/*.yml` and `ops/roles/**/*.yml`
- the same checker also verifies that all `ops` playbooks and role directories are explicitly listed in `FEATURES.md`
- agents working in `ops/` should run the checker before finishing their turn
