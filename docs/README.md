# Ops Docs

Documentation anchor for the `ops/` repo.

## Core operator docs

- [OPERATOR_RUNBOOK.md](OPERATOR_RUNBOOK.md): consolidated SOP and workflow map for the full `ops/` surface
- [FEATURES.md](FEATURES.md): authoritative playbook, role, and tag index used by the sync guard
- [SETUP_GUIDE.md](SETUP_GUIDE.md): workstation setup, checkout, and credential bootstrap

## Specialist docs

- [AI_SERVER.md](AI_SERVER.md)
- [REPO0_LUKS_NBDE_PLAN.md](REPO0_LUKS_NBDE_PLAN.md)
- [repo_migration/README.md](repo_migration/README.md)
- [infra-consulting-spec-single-machine.md](infra-consulting-spec-single-machine.md)

## Update rule

When `ops/` automation changes, update:

1. [FEATURES.md](FEATURES.md) for playbook, role, and tag inventory changes.
2. [OPERATOR_RUNBOOK.md](OPERATOR_RUNBOOK.md) when operator workflow, prerequisites, verification, or recovery guidance changes.
3. [AI_SERVER.md](AI_SERVER.md) when AI host workflow or the configured model inventory changes.
