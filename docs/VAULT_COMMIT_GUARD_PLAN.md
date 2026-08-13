# Ansible Vault Commit Guard Implementation Plan

## Objective

Prevent files that are required to be encrypted with Ansible Vault from being committed or merged as plaintext.

The guard must work at two layers:

1. a local Git pre-commit hook for fast feedback before a commit is created;
2. a GitHub Actions workflow that enforces the same rule for pushes and pull requests.

The GitHub check must not require the Ansible Vault password or decrypt any secret. It only verifies the encrypted file envelope.

## Current repository state

The tracked files currently required to remain encrypted are:

- `group_vars/all/vault.yml`
- `group_vars/prod_web/vault.yml`

Both currently begin with a valid Ansible Vault header:

```text
$ANSIBLE_VAULT;1.2;AES256;devops
```

The local vault password file is configured as `.vault_devops` in `ansible.cfg` and is already excluded by `.gitignore` through `.vault*`.

Before this implementation, the repository had no `.github/workflows/` configuration or pre-commit framework. The implementation described below is now present in the working tree and still requires commits, a push, a successful GitHub run, and branch-ruleset activation.

## Repository-wide sensitive-data audit

### Audit method

The audit covers:

- every file tracked in the current Git tree;
- high-confidence signatures for private keys and common cloud, GitHub, Google, Slack, and Stripe credentials;
- credential-like assignments, classified without printing their values;
- ignored files currently present under `keys/`;
- existing Ansible, Terraform, and shell references showing how credential files are consumed.

Audit output must never print secret values. Findings below identify only paths and credential classes.

### Current tracked-tree findings

No plaintext private-key envelope or high-confidence API-token signature was detected in the current tracked tree.

A full-history Gitleaks scan found six historical plaintext findings in `group_vars/all/vault.yml`: three credential fields in commit `f08a76f388a9b1d66b028a197e1e769a2dbb9163` and the same three fields in commit `e9c9ad771e6b74c4cf026db7cb6bbff53f65b600`. The current file is encrypted, but encryption does not remove old values from Git history. The exact six fingerprints are narrowly recorded in `.gitleaksignore` so enforcement can start without allowing any new occurrence. The affected repository token, API key, and API secret must be rotated with their providers, then the repository history should be cleaned and the six baseline entries removed.

The tracked credential-like fields inspected are references or runtime assignments rather than embedded credentials:

- `group_vars/all/main.yml` references values in encrypted `vault_all` data for authentication, privilege escalation, SMTP, GCP, and SonarDB;
- `group_vars/prod/main.yml` references vaulted Ubuntu Pro and privilege-escalation values;
- `roles/tailscale_admin/defaults/main.yml` references vaulted Tailscale API and auth keys;
- `tf/providers.tf` references Terraform variables for Spaceship credentials;
- `terraform.yml` references the ignored local GCP service-account path;
- `bin/loadenv.sh` assigns tokens obtained at runtime from KeePassXC and does not contain their literal values;
- `tf/ROBOT_VSWITCH_NOTES.md` contains the literal placeholder `<token>`, not a detected credential.

The two tracked `group_vars/**/vault.yml` files are correctly encrypted and must remain covered by the commit guard.

This signature audit reduces risk but cannot prove the absence of every possible secret. The implementation should add a general secret scanner in addition to the deterministic Ansible Vault policy check if broader detection is required.

### Ignored `keys/` findings

The audit found local ignored credential material under `keys/`, including SMTP secret material, SSH private keys, and a GCP service-account JSON file. The entire `keys/` directory remains ignored and outside this implementation. No file under `keys/` will be added, encrypted, modified, staged, committed, migrated, or deleted as part of the vault guard.

### General secret-scanning recommendation

The deterministic validator answers: “Are files that policy says must be vaulted actually vaulted?” It does not detect a secret added under an unexpected filename. Add a second GitHub/pre-commit check using a dedicated scanner such as Gitleaks:

- scan staged changes locally where available;
- scan pull requests and pushes in GitHub Actions;
- pin the scanner/action version;
- maintain a reviewed allowlist for documented placeholders only;
- fail without echoing full secret values;
- run a separate one-time full-history scan before declaring historical exposure clean.

The implementation can keep the standard-library vault validator as the authoritative format/policy check while using Gitleaks for heuristic repository-wide detection.

## Proposed policy

### Files covered

Use a version-controlled policy file containing explicit path globs rather than relying only on filenames. Initial pattern:

```text
group_vars/**/vault.yml
```

This automatically protects new environment or host-group vault files that follow the existing repository convention. The entire `keys/` directory remains outside policy and ignored.

### Accepted encrypted format

Every covered regular file must:

1. be non-empty;
2. have a first line matching an Ansible Vault header:
   `$ANSIBLE_VAULT;<format-version>;<cipher>` with an optional vault ID;
3. contain only non-empty hexadecimal payload lines after the header;
4. have no plaintext before or after the encrypted payload.

The implementation should accept supported Ansible Vault versions and vault IDs rather than hard-coding the current `1.2;AES256;devops` header.

### Failure behavior

For each violation, print:

- the path;
- the failed policy requirement;
- a remediation command, for example:
  `ansible-vault encrypt group_vars/example/vault.yml`.

Never print file contents because a failed file may contain a plaintext secret.

## Implementation components

### 1. Version-controlled policy file

Add a small policy file under `config/` or the repository root that lists protected globs. The preferred location is:

```text
config/ansible-vault-required-files.txt
```

Rules:

- one glob per line;
- blank lines ignored;
- lines beginning with `#` treated as comments;
- paths interpreted relative to the repository root.

Initial entry:

```text
group_vars/**/vault.yml
```

### 2. Shared validator

Add:

```text
bin/check_ansible_vault_encryption.py
```

Responsibilities:

- discover the Git repository root reliably;
- load protected patterns from the policy file;
- inspect tracked files matching those patterns;
- optionally inspect an explicit list of staged paths for local-hook use;
- validate only the vault envelope and never decrypt data;
- return `0` when every covered file is encrypted and a non-zero status otherwise;
- emit concise, non-secret diagnostics.

Suggested command modes:

```bash
python3 bin/check_ansible_vault_encryption.py
python3 bin/check_ansible_vault_encryption.py --staged
```

The all-files mode is used by GitHub Actions and manual validation. The staged mode reads file content from the Git index, not merely the working tree, so it validates exactly what will be committed and cannot be bypassed by staging plaintext and then restoring an encrypted working copy.

The script should use only Python's standard library so it runs without dependency installation.

### 3. Local Git hook

Add a version-controlled hook:

```text
.githooks/pre-commit
```

Behavior:

- invoke `python3 bin/check_ansible_vault_encryption.py --staged`;
- block the commit when a covered staged file is plaintext or malformed;
- pass immediately when no covered file is staged.

Because Git does not enable repository hooks automatically, document and provide a one-time setup command:

```bash
git config core.hooksPath .githooks
```

Do not modify developers' Git configuration automatically from Ansible or another routine command.

### 4. GitHub Actions workflow

Add:

```text
.github/workflows/ansible-vault-guard.yml
```

Triggers:

- `pull_request`;
- `push` to protected long-lived branches, initially `main`;
- optional `workflow_dispatch` for manual validation.

Workflow behavior:

1. check out the repository;
2. run `python3 bin/check_ansible_vault_encryption.py`;
3. require no repository or environment secrets;
4. grant read-only contents permission;
5. use a pinned major version of `actions/checkout`.

The resulting check can be configured as a required branch-protection status check in GitHub. The workflow alone reports failure; GitHub branch protection is what prevents merging or direct protected-branch updates.

### 5. Documentation

Update:

- `docs/OPERATOR_RUNBOOK.md` with local hook setup, normal usage, remediation, and GitHub branch-protection instructions;
- `docs/README.md` to link this plan while it remains a standalone operator document;
- `README.md` with a short security-check/setup pointer if local setup instructions are already maintained there.

`docs/FEATURES.md` does not need inventory changes unless the implementation adds an Ansible playbook, role, or tag. The documentation sync guard must still be run.

## Validation plan

### Validator tests

Use temporary Git repositories or script-level fixtures to verify:

1. the two existing encrypted vault files pass;
2. a covered plaintext YAML file fails;
3. a file with the vault header but plaintext payload fails;
4. a valid vault header with a vault ID passes;
5. an unrelated plaintext YAML file is ignored;
6. staged mode reads the index version rather than the working-tree version;
7. filenames containing spaces are handled safely;
8. diagnostics identify paths but never print their contents.

Automated tests should be added under `tests/` using Python `unittest`, avoiding new dependencies.

### Repository validation

Run:

```bash
python3 bin/check_ansible_vault_encryption.py
python3 -m unittest tests/test_check_ansible_vault_encryption.py
python3 bin/check_features_sync.py
```

Validate the workflow YAML structurally using available local tooling. No workflow run or remote GitHub configuration should be claimed as complete until GitHub executes the workflow.

## Rollout sequence

1. Add the policy file and shared validator.
2. Add validator unit tests and make them pass.
3. Add and manually exercise the local pre-commit hook.
4. Keep the entire `keys/` directory ignored and outside the change.
5. Add the GitHub Actions workflow using the same validator.
6. Add a pinned general secret scanner for unexpected credential paths.
7. Update operator documentation and the docs index.
8. Run repository validation, secret scans, and the docs sync guard.
9. Push the branch and confirm the GitHub Actions checks pass.
10. In GitHub branch protection for `main`, require the vault and general secret-scan status checks and restrict direct pushes if desired.

## Immediate implementation and commit sequence

The implementation files are already present in the working tree. Complete rollout using the following ordered commits. Do not add any plaintext private credential file.

### Prerequisite: install local tooling and activate hooks

From `ops/`:

```bash
brew install gitleaks
git config core.hooksPath .githooks
git config --get core.hooksPath
```

Expected hook path:

```text
.githooks
```

Do not commit `.vault_devops`; it remains ignored and is never needed by GitHub Actions.

### Commit 1: add deterministic vault enforcement and tests

Stage only the policy, validator, local hook, test, ignore rules, and GitHub workflow:

```bash
git add .gitignore
git add config/ansible-vault-required-files.txt
git add bin/check_ansible_vault_encryption.py
git add tests/test_check_ansible_vault_encryption.py
git add .githooks/pre-commit
git add .github/workflows/ansible-vault-guard.yml
git add .gitleaksignore
git diff --cached --check
python3 bin/check_ansible_vault_encryption.py
python3 -m unittest tests/test_check_ansible_vault_encryption.py
.githooks/pre-commit
git diff --cached --name-only
git commit -m "Add local Ansible Vault and secret commit guards"
```

Expected staged files before the commit:

```text
.gitignore
.githooks/pre-commit
bin/check_ansible_vault_encryption.py
config/ansible-vault-required-files.txt
tests/test_check_ansible_vault_encryption.py
.github/workflows/ansible-vault-guard.yml
.gitleaksignore
```

The hook itself runs during the commit. Gitleaks must be installed or the commit intentionally fails closed.

### Commit 2: add operator documentation

Stage only documentation:

```bash
git add README.md
git add docs/README.md
git add docs/OPERATOR_RUNBOOK.md
git add docs/VAULT_COMMIT_GUARD_PLAN.md
python3 bin/check_features_sync.py
git diff --cached --check
git diff --cached --name-only
git commit -m "Document vault and secret enforcement"
```

Before either commit, confirm that no path under `keys/` appears in `git diff --cached --name-only`. Also confirm `.vault_devops` is not staged.

### Push and validate GitHub Actions

The current GitHub remote is `origin` and targets `Helios-23/ll-ops`. Push the commits:

```bash
git status --short
git push origin main
```

Then inspect the workflow runs:

```bash
gh run list --repo Helios-23/ll-ops --workflow ansible-vault-guard.yml --limit 5
gh run watch RUN_ID --repo Helios-23/ll-ops --exit-status
```

Both jobs must pass:

- `Verify required Ansible Vault encryption`
- `Scan repository for exposed secrets`

The six known historical fingerprints are narrowly baselined in `.gitleaksignore`. Rotate the affected repository token, API key, and API secret, clean those two historical commits from all branches and tags, then remove the baseline entries. Any additional Gitleaks finding must fail the rollout and be reviewed; do not add a broad allowlist.

### Require checks through a GitHub ruleset

The workflow must run once before its status checks are selectable in GitHub. After the first successful run:

1. Open `https://github.com/Helios-23/ll-ops/settings/rules`.
2. Create a branch ruleset targeting the default branch `main`.
3. Set enforcement to `Active`.
4. Require a pull request before merging if direct pushes should be blocked.
5. Require status checks to pass.
6. Add both checks:
   - `Verify required Ansible Vault encryption`
   - `Scan repository for exposed secrets`
7. Require branches to be up to date before merging.
8. Block force pushes and branch deletion.
9. Do not add broad bypass actors; any emergency bypass should be explicit and audited.
10. Save the ruleset.

Verify the ruleset from the GitHub UI or, if authenticated with sufficient permission:

```bash
gh api repos/Helios-23/ll-ops/rulesets
```

### Verify enforcement with a safe test pull request

Use a temporary branch and a non-secret plaintext fixture under a protected path. Never test with real credentials:

```bash
git switch -c test/vault-guard
mkdir -p group_vars/vault_guard_test
printf 'example_password: not-a-real-secret\n' > group_vars/vault_guard_test/vault.yml
git add group_vars/vault_guard_test/vault.yml
git commit -m "Test vault guard rejection"
```

Expected result: the commit is rejected by the vault guard. Clean up without committing:

```bash
git restore --staged group_vars/vault_guard_test/vault.yml
rm -rf group_vars/vault_guard_test
git switch main
git branch -D test/vault-guard
```

The GitHub checks are validated by their successful run on the two implementation commits; there is no need to intentionally push plaintext to a remote branch.

## `keys/` exclusion

The entire `keys/` directory is deliberately excluded from this implementation. Do not add, encrypt, modify, stage, commit, migrate, or delete anything under it.

## Security boundaries and limitations

- Header/payload validation proves that covered files are Ansible Vault ciphertext; it does not prove that every secret has been placed in a covered file.
- The policy must be extended when the repository introduces a new secret-bearing path that does not match `group_vars/**/vault.yml`.
- Git hooks are local safeguards and can be bypassed with `git commit --no-verify`; GitHub Actions plus branch protection provide authoritative enforcement.
- GitHub Actions cannot prevent a secret from reaching an unprotected branch on the first push. It can fail that push's check and prevent merge. Preventing all direct pushes requires GitHub rulesets or branch protection.
- If plaintext secrets have already been committed, encrypting the current file does not remove them from Git history; history cleanup and credential rotation are separate incident-response steps.
- No vault password, vault identity secret, or decrypted value should ever be supplied to this workflow.

## Implementation decision

Proceed with a standard-library Python validator shared by a version-controlled Git pre-commit hook and a GitHub Actions workflow. Use the policy glob `group_vars/**/vault.yml`, validate the staged index locally, validate all tracked covered files in CI, and require the resulting GitHub check through branch protection. Add a separate pinned general secret scanner to catch credentials committed outside policy paths. Keep the entire `keys/` directory ignored and outside this implementation.
