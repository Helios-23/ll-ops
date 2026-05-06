# Epytype Operations

Infrastructure-as-code for epytype.org services. Ansible playbooks and Terraform configs for server provisioning, hardening, and application deployment.

## User Access Guide

For SSH setup, repository checkout, and migration workflow details, use `USER_GUIDE.md`.

## Prerequisites
The `kpxc/` directory must be pulled as a subdirectory of `ops/`:
```
<Epytype home>/ops/kpxc/epytype_ops.kdbx
```

## Load Credentials
From the `ops/` directory:

```bash
cd <Epytype home>/ops
source ./bin/loadenv.sh
```

This loads required credentials into your environment.
