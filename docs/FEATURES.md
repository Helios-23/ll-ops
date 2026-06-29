# Ansible Features

Compact index of the playbooks, roles, and tags in `ops/`.

Use this as the quick command map; the **Complete Tag Index** below is the authoritative tag list and is checked by `ops/bin/check_features_sync.py` when AI agents edit `ops/`.

`inventory/epytype` is configured in `ops/ansible.cfg`, so the examples below omit `-i` unless you are intentionally overriding the default inventory.

## Playbook Quick Map

| Playbook | Scope | Flow | Main tags | Focus tags |
| --- | --- | --- | --- | --- |
| `setup_epytype.yml` | `repo0`, `gex0`, `web0` | choose `repo_server`, `ai_server`, or `web_server` -> narrow to a role tag -> narrow to a task tag | `repo_server`, `ai_server`, `web_server` | `forgejo`, `forgejo_pull`, `harden`, `ai_rig`, `lantern`, `ipv4-forward`, `forgejo_users`, `ollama`, `pull_models`, `show_models`, `webui`, `ai_nginx`, `ai_certbot` |
| `deploy.yml` | `web0` | choose `lantern_runtime` to install a staged Lantern `.deb` and restart the Lantern services on `web0`, or choose `lantern_app` to sync and extract a Lantern app bundle into `/srv/lantern/apps/<app_id>` | `lantern_runtime`, `lantern_app` | `lantern_runtime`, `lantern_app` |
| `release.yaml` | `localhost` | stage fresh Lantern binaries on the controller, build the `.deb` with a `+git<sha>` version suffix and dirty-tree marker when needed, and leave the package in the release output directory; package payload includes only `atlas_studio` and `graph_studio` | `lantern_release` | `lantern_release` |
| `repo0_nbde.yml` | `repo0` | provide vaulted LUKS/Clevis vars -> run preflight on an already encrypted host -> bind Clevis and rebuild initramfs | `repo0_nbde` | `luks_nbde` |
| `admin.yml` | `all` with `-l/--limit` required | choose hosts -> run `admin` or `update_reboot` -> use Tailscale tags if needed | `admin` | `update_reboot`, `tailscale`, `tailscale_machine`, `tailscale_policy` |
| `github-release.yml` | localhost | choose `epytype` or `lantern` -> optionally override version vars -> run from `ops/` | `epytype`, `lantern` | release variables only; no extra Ansible task tags |
| `terraform.yml` | localhost | run plan -> apply automatically on drift -> sync inventory from outputs | `terraform` | none |
| `kymstr.yml` | selected hosts | choose hosts -> run `kymstr` or an explicit opt-in task tag -> many paths also require `never` | `kymstr` | `ssh-auth`, `ssh-key`, `gen-csr`, `encrypt`, `cert`, `never` |
| `lantern-app-deploy.yml` | `web0` | thin wrapper that imports `deploy.yml` for Lantern app/runtime deploy flows | inherited from `deploy.yml` | `lantern_runtime`, `lantern_app`, `lantern_app_deploy` |
| `lantern-release-deploy.yml` | localhost, `web0` | thin wrapper that imports `release.yaml` and then `deploy.yml` | inherited from imported playbooks | `lantern_release`, `lantern_runtime`, `lantern_app`, `lantern_app_deploy` |

## Examples

### `setup_epytype.yml`

```bash
apb setup_epytype.yml
apb setup_epytype.yml -l repo0 -t forgejo
apb setup_epytype.yml -l repo0 -t forgejo_pull
apb setup_epytype.yml -l repo0 -t forgejo_users
apb setup_epytype.yml -l gex0 -t ai_rig
apb setup_epytype.yml -l web0 -t lantern
apb setup_epytype.yml -l gex0 -t ollama
apb setup_epytype.yml -l gex0 -t pull_models
apb setup_epytype.yml -l gex0 -t show_models
```

### `repo0_nbde.yml`

```bash
apb repo0_nbde.yml
apb repo0_nbde.yml -t luks_nbde
```

### `admin.yml`

```bash
apb admin.yml -l repo0
apb admin.yml -l repo0 -t update_reboot
apb admin.yml -l repo0 -t tailscale
apb admin.yml -l repo0 -t tailscale_machine
apb admin.yml -l repo0 -t tailscale_policy
```

### `github-release.yml`

```bash
apb github-release.yml
apb github-release.yml -t epytype
apb github-release.yml -t lantern
apb github-release.yml -t epytype -e epytype_release_number=0
apb github-release.yml -t epytype -e epytype_release_version=0.1.1
```

### `terraform.yml`

```bash
apb terraform.yml -t terraform
```

### `kymstr.yml`

```bash
apb kymstr.yml -l repo0
apb kymstr.yml -l repo0 -t ssh-auth
apb kymstr.yml -l repo0 -t gen-csr
apb kymstr.yml -l repo0 -t cert
```

## Role Task Areas

### `roles/keymaster`

| Task area | Tags | Purpose | Notes |
| --- | --- | --- | --- |
| dependency bootstrap | `install`, `never` | install `pyOpenSSL` locally and remotely where needed | intentionally opt-in |
| vault encryption | `encrypt`, `never` | encrypt site cert material with `ansible-vault` | runs on localhost |
| SSH key generation | `gen-ssh`, `ssh-gen`, `never` | create local Ed25519 keypairs from `auth_keys` inventory | localhost only |
| CSR generation and review | `gen-csr`, `check-csr`, `never` | build private keys and CSRs, then inspect subject fields | localhost only |
| SSH authorization rollout | `ssh-auth`, `never` | remove unauthorized keys, install authorized keys, rotate comments | runs against selected hosts |
| access review reporting | `ssh-auth-review`, `never` | produce a simple local auth report for configured users and environments | writes local report files |
| key fingerprint reporting | `ssh-key-report`, `never` | inspect deployed `authorized_keys` fingerprints per host | writes local report files |
| automation key install | `ssh-key`, `never` | place private/public automation keys for `ssh_user` on remote hosts | verify template paths before use |
| certificate deployment | `cert`, `never` | copy site certs and private keys to remote SSL paths | use only after local material is ready |
| MySQL helper tasks | `mysql`, `never` | run included MySQL-specific keymaster tasks | see `roles/keymaster/tasks/mysql.yml` |

### `roles/epytype_release`

| Task area | Selector | Purpose | Notes |
| --- | --- | --- | --- |
| Epytype release prep | play tag `epytype` | compute next version, update tracked files, run checks, commit, tag, and push `HEAD:release` | defaults target `../epytype` |
| Lantern release prep | play tag `lantern` | reuse the same role with Lantern-specific version source and checks | defaults target `../lantern` |
| explicit version override | `-e epytype_release_version=x.y.z` | force an exact release version | bypasses auto bump logic |
| explicit patch/release number | `-e epytype_release_number=N` | keep major/minor and set patch explicitly | useful for initial release in a new line |
| local check gate | `epytype_release_run_checks=true` | run the repo-specific release checks before commit/tag/push | disable only for deliberate recovery work |
| push controls | `epytype_release_push`, `epytype_release_push_github`, `epytype_release_create_tag` | control Forgejo branch push, GitHub mirror push, and tag creation | GitHub mirror excludes `docs/release-automation.md` |

## Complete Tag Index

### Play-level tags

| Tags |
| --- |
| `admin`, `ai_server`, `epytype`, `kymstr`, `lantern`, `lantern_app_deploy`, `lantern_app`, `lantern_release`, `lantern_runtime`, `repo0_nbde`, `repo_server`, `terraform`, `web_server` |

### Role-level tags

| Tags |
| --- |
| `ai_rig`, `ai_certbot`, `ai_nginx`, `certbot_tls`, `docker_engine`, `forgejo`, `forgejo_pull`, `harden`, `lantern`, `lantern_app`, `lantern_app_deploy`, `lantern_release`, `lantern_runtime`, `luks_nbde`, `nginx`, `tailscale`, `ubuntu_pro_fips` |

### Task-level tags

| Tags |
| --- |
| `always`, `ai_certbot`, `ai_nginx`, `cert`, `check-csr`, `encrypt`, `fail2ban`, `fail2ban_sshd_invalid_user`, `forgejo_push_create_org`, `forgejo_reverse_proxy_trust`, `forgejo_tailscale_access_control`, `forgejo_users`, `gen-csr`, `gen-ssh`, `install`, `ipv4-forward`, `lantern_app`, `lantern_app_deploy`, `lantern_release`, `lantern_runtime`, `mysql`, `never`, `ollama`, `pull_models`, `reverse_proxy_fail2ban`, `show_models`, `ssh-auth`, `ssh-auth-review`, `ssh-gen`, `ssh-key`, `ssh-key-report`, `tailscale_machine`, `tailscale_policy`, `update_reboot`, `webui` |

## Role Notes

| Role | Main tags | Extra tags / notes |
| --- | --- | --- |
| `roles/luks_nbde_client` | `luks_nbde` | client-side only; intended for hosts already installed on LUKS. Use with `repo0_nbde.yml` after provisioning or offline migration. |
| `roles/forgejo_container` | `forgejo` | Extra tags: `forgejo_push_create_org`, `forgejo_users`, `forgejo_reverse_proxy_trust`, `forgejo_tailscale_access_control`, `never`. `forgejo_users` is opt-in because it is also tagged `never`. Feature booleans: `forgejo_reverse_proxy_trust_feature_enabled`, `forgejo_tailscale_access_control_feature_enabled`. |
| `roles/forgejo_pull` | `forgejo_pull` | Installs the repo0 `devops` Forgejo SSH keypairs, SSH config, known_hosts entry, and git URL rewrite so local builds can pull via SSH. |
| `roles/harden` | `harden` | Extra tags: `fail2ban`, `fail2ban_sshd_invalid_user`, `ipv4-forward`, `reverse_proxy_fail2ban`. Feature booleans: `fail2ban_feature_forgejo_enabled`, `fail2ban_feature_reverse_proxy_enabled`, `fail2ban_feature_sshd_invalid_user_enabled`. |
| `roles/tailscale_admin` | `tailscale`, `tailscale_machine`, `tailscale_policy` | `tailscale_machine` covers host-side install and `tailscale up`; `tailscale_policy` pushes tailnet ACL/SSH policy. Feature booleans: `tailscale_machine_enabled`, `tailscale_policy_enabled`. |
| `roles/ai_rig` | `ai_rig` | Extra tags: `ai_certbot`, `ai_nginx`, `ollama`, `pull_models`, `show_models`, `webui`. `ai_nginx` is the narrow path for the AI vhost only. `ai_certbot` is the TLS issuance/renewal path. `pull_models` is narrower than `ollama` and useful for model refreshes after stack setup. `show_models` prints the current Ollama roster in a terminal-friendly multiline list. |
| `roles/lantern` | `lantern` | Lantern reverse proxy and TLS rollout for `lantern.epytype.org`; manages the nginx vhost, certbot issuance, and renewal cron on `web0` during the new web-host migration path. The nginx vhost issues a `301 /atlas` redirect for the root path so that `https://lantern.epytype.org/` lands on the Atlas app. |
| `roles/lantern_app_deploy` | `lantern_app_deploy` | Syncs the Lantern repo on the controller, reads the controller git SHA after sync, archives a selected app bundle only when the bundle changes, names the archive with the build timestamp plus the 8-char git SHA and the bundle fingerprint short hash, and extracts it into `/srv/lantern/apps/<app_id>` on `web0` with `lantern:lantern` ownership whenever the bundle changes or the controller archive basename differs from the deployed archive marker on the target; the target caches deployed archives under `/srv/lantern/apps/<app_id>/.archives/` and only updates `.deployed-archive` after a successful extraction. |
| `roles/lantern_deploy` | `lantern_deploy` | Installs a built Lantern `.deb` on `web0` with `dpkg -i` plus `apt-get -f install -y`, then starts `lantern.service` and `lantern-ha.service` and removes older staged `.deb` files from the target host while keeping the current package. |
| `roles/admin` | none | Task tag: `update_reboot` only. The package update and reboot path runs only when `update_reboot` is selected. |
| `roles/epytype_release` | none | release helper role used by `github-release.yml`; see task areas above for versioning, check gate, and push controls. |
| `roles/keymaster` | none | task areas are documented above. Many paths are intentionally guarded by `never` and should be run with host limits and explicit tag selection. |
| `roles/certbot_tls` | `certbot_tls` | no extra documented task tags |
| `roles/docker_engine` | `docker_engine` | no extra documented task tags |
| `roles/nginx` | `nginx` | no extra documented task tags |
| `roles/ubuntu_pro_fips` | `ubuntu_pro_fips` | no extra documented task tags |

## Agent Guard

For AI-agent edits inside `ops/`:

- `ops/AGENTS.md` tells agents to treat `ops/docs/FEATURES.md`, `ops/docs/OPERATOR_RUNBOOK.md`, and `ops/docs/README.md` as part of the `ops` change surface
- `ops/bin/check_features_sync.py` checks that the **Complete Tag Index** matches the tags present in `ops/*.yml` and `ops/roles/**/*.yml`
- the same checker also verifies that all `ops` playbooks and role directories are explicitly listed in `FEATURES.md`
- agents working in `ops/` should run the checker before finishing their turn
