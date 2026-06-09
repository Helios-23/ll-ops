# Ansible Features

Compact index of the playbooks, roles, and tags in `ops/`.

Use this as the quick command map; the **Complete Tag Index** below is the authoritative tag list and is checked by `ops/bin/check_features_sync.py` when AI agents edit `ops/`.

## Playbook Quick Map

| Playbook | Scope | Flow | Main tags | Focus tags |
| --- | --- | --- | --- | --- |
| `setup_epytype.yml` | `repo0`, `gex0` | choose `repo_server` or `ai_server` → narrow to a role tag → narrow to a task tag | `repo_server`, `ai_server` | `forgejo`, `harden`, `ai_rig`, `ipv4-forward`, `forgejo_users`, `ollama`, `pull_models`, `webui` |
| `repo0_nbde.yml` | `repo0` | provide vaulted LUKS/Clevis vars → run preflight on an already encrypted host → bind Clevis and rebuild initramfs | `repo0_nbde` | `luks_nbde` |
| `admin.yml` | `all` with `-l/--limit` required | choose hosts → run `admin` or `update_reboot` → use Tailscale tags if needed | `admin` | `update_reboot`, `tailscale`, `tailscale_machine`, `tailscale_policy` |
| `github-release.yml` | localhost | choose `epytype` or `lantern` → optionally override version vars → run from `ops/` | `epytype`, `lantern` | release variables only; no extra task tags documented here |
| `terraform.yml` | localhost | run plan → apply automatically on drift → sync inventory from outputs | `terraform` | none |
| `kymstr.yml` | selected hosts | choose hosts → run `kymstr` or an explicit opt-in task tag → many paths also require `never` | `kymstr` | `ssh-auth`, `ssh-key`, `gen-csr`, `encrypt`, `cert`, `never` |

## Examples

### `setup_epytype.yml`

```bash
ansible-playbook ops/setup_epytype.yml
ansible-playbook ops/setup_epytype.yml --tags repo_server
ansible-playbook ops/setup_epytype.yml --tags repo_server,forgejo
ansible-playbook ops/setup_epytype.yml --tags repo_server,forgejo_users
ansible-playbook ops/setup_epytype.yml --tags ai_server,ai_rig
ansible-playbook ops/setup_epytype.yml --tags ai_server,ollama
ansible-playbook ops/setup_epytype.yml --tags ai_server,pull_models
```

### `repo0_nbde.yml`

```bash
ansible-playbook ops/repo0_nbde.yml -i ops/inventory/epytype
ansible-playbook ops/repo0_nbde.yml -i ops/inventory/epytype --tags luks_nbde
```

### `admin.yml`

```bash
ansible-playbook ops/admin.yml -i ops/inventory/epytype -l repo0
ansible-playbook ops/admin.yml -i ops/inventory/epytype -l repo0 --tags update_reboot
ansible-playbook ops/admin.yml -i ops/inventory/epytype -l repo0 --tags tailscale
ansible-playbook ops/admin.yml -i ops/inventory/epytype -l repo0 --tags tailscale_machine
ansible-playbook ops/admin.yml -i ops/inventory/epytype -l repo0 --tags tailscale_policy
```

### `github-release.yml`

```bash
ansible-playbook ops/github-release.yml
ansible-playbook ops/github-release.yml --tags epytype
ansible-playbook ops/github-release.yml --tags lantern
```

### `terraform.yml`

```bash
ansible-playbook ops/terraform.yml --tags terraform
```

### `kymstr.yml`

```bash
ansible-playbook ops/kymstr.yml -i ops/inventory/epytype -l repo0
ansible-playbook ops/kymstr.yml -i ops/inventory/epytype -l repo0 --tags ssh-auth
ansible-playbook ops/kymstr.yml -i ops/inventory/epytype -l repo0 --tags gen-csr
ansible-playbook ops/kymstr.yml -i ops/inventory/epytype -l repo0 --tags cert
```

## Complete Tag Index

### Play-level tags

| Tags |
| --- |
| `admin`, `ai_server`, `epytype`, `kymstr`, `lantern`, `repo0_nbde`, `repo_server`, `terraform` |

### Role-level tags

| Tags |
| --- |
| `ai_rig`, `certbot_tls`, `docker_engine`, `forgejo`, `harden`, `luks_nbde`, `nginx`, `tailscale`, `ubuntu_pro_fips` |

### Task-level tags

| Tags |
| --- |
| `always`, `cert`, `check-csr`, `encrypt`, `forgejo_push_create_org`, `forgejo_reverse_proxy_trust`, `forgejo_tailscale_access_control`, `forgejo_users`, `gen-csr`, `gen-ssh`, `install`, `ipv4-forward`, `mysql`, `never`, `ollama`, `pull_models`, `reverse_proxy_fail2ban`, `ssh-auth`, `ssh-auth-review`, `ssh-gen`, `ssh-key`, `ssh-key-report`, `tailscale_machine`, `tailscale_policy`, `update_reboot`, `webui` |

## Role Notes

| Role | Main tags | Extra tags / notes |
| --- | --- | --- |
| `roles/luks_nbde_client` | `luks_nbde` | client-side only; intended for hosts already installed on LUKS. Use with `repo0_nbde.yml` after provisioning or offline migration. |
| `roles/forgejo_container` | `forgejo` | Extra tags: `forgejo_push_create_org`, `forgejo_users`, `forgejo_reverse_proxy_trust`, `forgejo_tailscale_access_control`, `never`. `forgejo_users` is opt-in because it is also tagged `never`. Feature booleans: `forgejo_reverse_proxy_trust_feature_enabled`, `forgejo_tailscale_access_control_feature_enabled`. |
| `roles/harden` | `harden` | Extra tags: `ipv4-forward`, `reverse_proxy_fail2ban`. Feature booleans: `fail2ban_feature_forgejo_enabled`, `fail2ban_feature_reverse_proxy_enabled`. |
| `roles/tailscale_admin` | `tailscale`, `tailscale_machine`, `tailscale_policy` | `tailscale_machine` covers host-side install and `tailscale up`; `tailscale_policy` pushes tailnet ACL/SSH policy. Feature booleans: `tailscale_machine_enabled`, `tailscale_policy_enabled`. |
| `roles/ai_rig` | `ai_rig` | Extra tags: `ollama`, `pull_models`, `webui`. `pull_models` is narrower than `ollama` and useful for model refreshes after stack setup. |
| `roles/admin` | none | Task tag: `update_reboot` only. The package update and reboot path runs only when `update_reboot` is selected. |
| `roles/epytype_release` | none | release helper role with defaults only; not currently wired into a documented playbook. |
| `roles/keymaster` | none | Task tags: `install`, `encrypt`, `gen-ssh`, `ssh-gen`, `gen-csr`, `check-csr`, `mysql`, `ssh-auth`, `ssh-auth-review`, `ssh-key-report`, `ssh-key`, `cert`, `never`. Many paths are intentionally guarded by `never`. |
| `roles/certbot_tls` | `certbot_tls` | no extra documented task tags |
| `roles/docker_engine` | `docker_engine` | no extra documented task tags |
| `roles/nginx` | `nginx` | no extra documented task tags |
| `roles/ubuntu_pro_fips` | `ubuntu_pro_fips` | no extra documented task tags |

## Agent Guard

For AI-agent edits inside `ops/`:

- `ops/AGENTS.md` tells Zed agents to treat `ops/FEATURES.md` as part of the `ops` change surface
- `ops/bin/check_features_sync.py` checks that the **Complete Tag Index** matches the tags present in `ops/*.yml` and `ops/roles/**/*.yml`
- the same checker also verifies that all `ops` playbooks and role directories are explicitly listed in `FEATURES.md`
- agents working in `ops/` should run the checker before finishing their turn
