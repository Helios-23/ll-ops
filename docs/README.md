# Ops Docs

Documentation root for the `ops` repo.

## Core operator docs

- [OPERATOR_RUNBOOK.md](OPERATOR_RUNBOOK.md): top-level operating workflow for the current environment
- [FEATURES.md](FEATURES.md): authoritative playbook, role, and tag inventory
- [SETUP_GUIDE.md](SETUP_GUIDE.md): workstation setup, checkout, and credential bootstrap

## Specialist docs

- [EMAIL_CONFIG.md](EMAIL_CONFIG.md): email routing and mailbox setup notes
- [infra-consulting-spec-single-machine.md](infra-consulting-spec-single-machine.md): infrastructure planning notes

## Update Rules

When `ops/` automation changes, update:

1. [FEATURES.md](FEATURES.md) for playbook, role, or tag inventory changes.
2. [OPERATOR_RUNBOOK.md](OPERATOR_RUNBOOK.md) when operator workflow, prerequisites, verification, or recovery guidance changes.
3. This index when operator docs are added, removed, or renamed.
