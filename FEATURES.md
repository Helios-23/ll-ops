# Ansible Features

This file is a compact index of the playbooks, plays, roles, and major tags in `ops/`.

Use it as a command library when deciding which playbook/tag combination to run.

## Playbooks

### `repo-server.yml`

Purpose:

- configure `repo0`
- apply baseline hardening
- manage Docker, nginx, TLS, and Forgejo

Play:

- `Configure repo server baseline and Forgejo`

Hosts:

- `repo0`

Role tags:

- `ubuntu_pro_fips`
- `harden`
- `docker_engine`
- `nginx`
- `certbot_tls`
- `forgejo`

Examples:

```bash
ansible-playbook ops/repo-server.yml -i ops/inventory/epytype -l repo0
ansible-playbook ops/repo-server.yml -i ops/inventory/epytype -l repo0 --tags forgejo
ansible-playbook ops/repo-server.yml -i ops/inventory/epytype -l repo0 --tags harden
```

### `ai-server.yml`

Purpose:

- configure `gex0`
- apply baseline hardening
- manage Docker, nginx, TLS, and AI services

Play:

- `Configure AI server baseline and AI stack`

Hosts:

- `gex0`

Role tags:

- `harden`
- `docker_engine`
- `nginx`
- `certbot_tls`
- `ai_rig`

Examples:

```bash
ansible-playbook ops/ai-server.yml -i ops/inventory/epytype -l gex0
ansible-playbook ops/ai-server.yml -i ops/inventory/epytype -l gex0 --tags ai_rig
```

### `admin.yml`

Purpose:

- run administrative tasks across selected hosts
- optionally manage Tailscale policy/machine settings

Play:

- `Run administrative tasks`

Hosts:

- `all` with `-l/--limit` required

Play tags:

- `admin`

Role tags:

- `tailscale`

Examples:

```bash
ansible-playbook ops/admin.yml -i ops/inventory/epytype -l repo0
ansible-playbook ops/admin.yml -i ops/inventory/epytype -l repo0 --tags tailscale
```

### `github-release.yml`

Purpose:

- prepare and publish releases from localhost

Plays:

- `Prepare and publish an Epytype release`
- `Prepare and publish a Lantern release`

Play tags:

- `epytype`
- `lantern`

Examples:

```bash
ansible-playbook ops/github-release.yml --tags epytype
ansible-playbook ops/github-release.yml --tags lantern
```

### `terraform.yml`

Purpose:

- initialize, plan, and apply Terraform from localhost
- sync resulting server data into Ansible inventory

Play:

- `Manage Terraform infrastructure and sync Ansible inventory`

Play tags:

- `terraform`

Example:

```bash
ansible-playbook ops/terraform.yml --tags terraform
```

### `kymstr.yml`

Purpose:

- run the `keymaster` role against selected hosts

Play tags:

- `kymstr`

Example:

```bash
ansible-playbook ops/kymstr.yml -i ops/inventory/epytype -l repo0
```

## Role Tag Index

### `roles/forgejo_container`

Main role tag:

- `forgejo`

Additional role/task tags:

- `forgejo_push_create_org`
- `forgejo_users`
- `forgejo_reverse_proxy_trust`
- `forgejo_tailscale_access_control`

Feature booleans:

- `forgejo_reverse_proxy_trust_feature_enabled`
- `forgejo_tailscale_access_control_feature_enabled`

Notes:

- `forgejo_reverse_proxy_trust` enables Forgejo trusted proxy CIDRs when the boolean is true
- `forgejo_tailscale_access_control` enables nginx `allow`/`deny` rules for Tailscale CIDRs when the boolean is true

### `roles/harden`

Main role tag:

- `harden`

Additional task tags:

- `ipv4-forward`
- `reverse_proxy_fail2ban`

Feature booleans:

- `fail2ban_feature_forgejo_enabled`
- `fail2ban_feature_reverse_proxy_enabled`

Notes:

- `ipv4-forward` persists `net.ipv4.ip_forward=1`
- `reverse_proxy_fail2ban` enables a Fail2ban jail against reverse-proxy access logs for repeated 401/403 responses when the boolean is true
- Forgejo SSH log monitoring is enabled by `fail2ban_feature_forgejo_enabled`

### `roles/tailscale_admin`

Primary tags:

- `tailscale`
- `tailscale_machine`
- `tailscale_policy`

Feature booleans:

- `tailscale_machine_enabled`
- `tailscale_policy_enabled`

Notes:

- `tailscale_machine` covers host-side Tailscale installation and `tailscale up`
- `tailscale_policy` pushes tailnet ACL/SSH policy via the API

### `roles/ai_rig`

Main role tag:

- `ai_rig`

Notes:

- deployed through `ai-server.yml`

### `roles/certbot_tls`

Main role tag:

- `certbot_tls`

### `roles/docker_engine`

Main role tag:

- `docker_engine`

### `roles/nginx`

Main role tag:

- `nginx`

### `roles/ubuntu_pro_fips`

Main role tag:

- `ubuntu_pro_fips`

## Common Command Patterns

Repo server:

```bash
ansible-playbook ops/repo-server.yml -i ops/inventory/epytype -l repo0
ansible-playbook ops/repo-server.yml -i ops/inventory/epytype -l repo0 --tags forgejo
ansible-playbook ops/repo-server.yml -i ops/inventory/epytype -l repo0 --tags harden
ansible-playbook ops/repo-server.yml -i ops/inventory/epytype -l repo0 --tags ipv4-forward
```

AI server:

```bash
ansible-playbook ops/ai-server.yml -i ops/inventory/epytype -l gex0
ansible-playbook ops/ai-server.yml -i ops/inventory/epytype -l gex0 --tags ai_rig
```

Tailscale administration:

```bash
ansible-playbook ops/admin.yml -i ops/inventory/epytype -l repo0 --tags tailscale
ansible-playbook ops/admin.yml -i ops/inventory/epytype -l repo0 --tags tailscale_policy
ansible-playbook ops/admin.yml -i ops/inventory/epytype -l repo0 --tags tailscale_machine
```
