# Logical Light Operations

Infrastructure-as-code for the Logical Light environment. This repo contains Ansible playbooks, Terraform configuration, and operator docs for the current Pharos deployment flow.

## Setup Guide

For workstation setup, SSH prerequisites, repository checkout, and credential bootstrap, start with [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md).

## Prerequisites

- Run commands from `ops/` unless a doc says otherwise.
- Load credentials before running automation:
  ```bash
  source ./bin/loadenv.sh
  ```
- Keep the required local checkouts available next to `ops/`:
  - `../pharos`
  - `../epytype`
- Have working `ansible`, `terraform`, `python3`, `git`, and `gitleaks` installed locally. On macOS: `brew install gitleaks`.

## Inventory and source of truth

- default inventory: `inventory/logicallight`
- group vars: `group_vars/all`, `group_vars/prod`, `group_vars/prod_web`
- Terraform root: `tf/`
- playbooks: top-level `*.yml`
- roles: `roles/`
- operator docs: `docs/`

## Operator docs

- [docs/OPERATOR_RUNBOOK.md](docs/OPERATOR_RUNBOOK.md) for the top-level workflow map
- [docs/FEATURES.md](docs/FEATURES.md) for the authoritative playbook, role, and tag inventory
- [docs/README.md](docs/README.md) for the docs index
- [docs/VAULT_COMMIT_GUARD_PLAN.md](docs/VAULT_COMMIT_GUARD_PLAN.md) for the Ansible Vault enforcement design and sensitive-data audit

## Commit security guard

Enable the repository-managed pre-commit hook once per checkout:

```bash
git config core.hooksPath .githooks
```

The hook validates staged `group_vars/**/vault.yml` files from the Git index, rejects plaintext or malformed Ansible Vault content, and runs Gitleaks against staged changes. It fails closed if Gitleaks is unavailable. Run the complete tracked-file vault check manually with:

```bash
python3 bin/check_ansible_vault_encryption.py
```

The entire `keys/` directory remains ignored and outside this implementation.
