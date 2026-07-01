# Epytype Operations

Infrastructure-as-code for epytype.org services. Ansible playbooks and Terraform configs for server provisioning, hardening, and application deployment.

## Setup Guide

For SSH setup, repository checkout, and migration workflow details, use [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md).

## Prerequisites

- Get the `kpxc` database. The `kpxc/` directory must be pulled as a subdirectory of `ops/`:
  ```
  <epytype_home>/ops/kpxc/epytype_ops.kdbx
  ```
- Load credentials from the `ops/` directory:
  ```bash
  cd <epytype_home>/ops
  source ./bin/loadenv.sh
  ```

  For editor/tooling shells such as Zed, `loadenv.sh` now skips the interactive KeePass password prompt unless you explicitly force it with `EPYTYPE_FORCE_LOADENV=1`. For non-interactive usage you can also preseed `KEEPASSXC_DB_PASSWORD` before sourcing the script.

This loads required credentials into your environment.

## Features

The operator documentation root lives in [docs/](docs/README.md).

- use [docs/OPERATOR_RUNBOOK.md](docs/OPERATOR_RUNBOOK.md) for the consolidated operator SOP
- use [docs/FEATURES.md](docs/FEATURES.md) for the authoritative playbook, role, and tag inventory
