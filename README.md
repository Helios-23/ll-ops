# Epytype Operations

Infrastructure-as-code for epytype.org services. Ansible playbooks and Terraform configs for server provisioning, hardening, and application deployment.

## User Access Guide

For SSH setup, repository checkout, and migration workflow details, use `USER_GUIDE.md`.

## Features

For a compact index of playbooks, roles, and the complete documented Ansible tag set in `ops/`, use [FEATURES.md](FEATURES.md).

`FEATURES.md` is guarded for AI-agent work in `ops/` by `ops/AGENTS.md` and `ops/bin/check_features_sync.py`, so tag drift, new playbooks, new roles, and undocumented ops feature changes are caught during agent edits instead of only after push.

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

## Release Epytype

Prepare, version, tag, and push an Epytype release from one Ansible command:

```bash
ansible-playbook github-release.yml
```

The `epytype_release` role composes `major.minor.release`, commits the release
prep, pushes `release` and the release tag to Forgejo, and pushes the same
branch/tag to the configured GitHub repo. Edit `epytype_release_major_version`
or `epytype_release_minor_version` for a new major/minor line; the release
number resets to `0` when either changes.
