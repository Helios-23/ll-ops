# Epytype Operations

Infrastructure-as-code for epytype.org services. Ansible playbooks and Terraform configs for server provisioning, hardening, and application deployment.

## Setup Guide

For SSH setup, repository checkout, and migration workflow details, use [SETUP_GUIDE.md](SETUP_GUIDE.md).

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

This loads required credentials into your environment.

## Features

For a compact index of playbooks, roles, the complete documented Ansible tag set in `ops/`, and release workflow commands such as `github-release.yml`, use [FEATURES.md](FEATURES.md).
