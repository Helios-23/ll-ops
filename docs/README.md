# Ops Docs

Documentation root for the `ops` repo.

## Core operator docs

- [OPERATOR_RUNBOOK.md](OPERATOR_RUNBOOK.md): top-level operating workflow, including the dedicated auth Nginx tenant, Spaceship DNS and Keycloak Compose service on the shared QA/production host
- [FEATURES.md](FEATURES.md): authoritative playbook, role, and tag inventory
- [SETUP_GUIDE.md](SETUP_GUIDE.md): workstation setup, checkout, and credential bootstrap
- [VAULT_COMMIT_GUARD_PLAN.md](VAULT_COMMIT_GUARD_PLAN.md): implementation plan for local and GitHub enforcement of required Ansible Vault encryption

## Specialist docs

- [KEYCLOAK_QA_ACCEPTANCE.md](KEYCLOAK_QA_ACCEPTANCE.md): verified shared-host auth tenant rollout and remaining application acceptance scope

- [infra-consulting-spec-single-machine.md](infra-consulting-spec-single-machine.md): infrastructure planning notes

## Update Rules

When `ops/` automation changes, update:

1. [FEATURES.md](FEATURES.md) for playbook, role, or tag inventory changes.
2. [OPERATOR_RUNBOOK.md](OPERATOR_RUNBOOK.md) when operator workflow, prerequisites, verification, or recovery guidance changes.
3. This index when operator docs are added, removed, or renamed.
