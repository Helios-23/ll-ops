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
- Have working `ansible`, `terraform`, `python3`, and `git` installed locally.

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
