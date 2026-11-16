# Ops Docs

Documentation root for the `ops` repo.

## Core operator docs

- [OPERATOR_RUNBOOK.md](OPERATOR_RUNBOOK.md): top-level operating workflow, standard E2-medium/40 GiB provisioning profile, Proof operator credential provisioning and private local copies, dedicated auth Nginx tenant, Spaceship DNS, Keycloak Compose service and isolated HTTPS subscription service with sandbox payments and real SMTP on the shared QA/production host
- [FEATURES.md](FEATURES.md): authoritative playbook, role, and tag inventory
- [SETUP_GUIDE.md](SETUP_GUIDE.md): workstation setup, checkout, and credential bootstrap
- [VAULT_COMMIT_GUARD_PLAN.md](VAULT_COMMIT_GUARD_PLAN.md): implementation plan for local and GitHub enforcement of required Ansible Vault encryption

## Specialist docs

- [PHAROS_QA_SERVICES.md](PHAROS_QA_SERVICES.md): capacity-gated, local-image ClamAV and dedicated PostgreSQL service preparation without application or database cutover

- [KEYCLOAK_QA_ACCEPTANCE.md](KEYCLOAK_QA_ACCEPTANCE.md): verified shared-host auth tenant rollout, operator resilience acceptance and application integration scope

- [infra-consulting-spec-single-machine.md](infra-consulting-spec-single-machine.md): infrastructure planning notes

## Update Rules

When `ops/` automation changes, update:

1. [FEATURES.md](FEATURES.md) for playbook, role, or tag inventory changes.
2. [OPERATOR_RUNBOOK.md](OPERATOR_RUNBOOK.md) when operator workflow, prerequisites, verification, or recovery guidance changes.
3. This index when operator docs are added, removed, or renamed.

The operator runbook records the approved local QA access artifact location and retained Keycloak acceptance reports, independently of retired development worktrees.

The access-service workflow requires prepared host database/encryption settings and supports a separate server-only database environment file; see the operator runbook for configuration and retained-order adoption prerequisites.

App deployments support protected target-only environment files for generic database migrations; the prepared-app section of the operator runbook describes ownership, permissions and execution.
