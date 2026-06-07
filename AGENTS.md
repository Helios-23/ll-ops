# Agent Notes

## `ops/` documentation sync guard

When you edit files anywhere under `ops/`, treat `ops/FEATURES.md` as part of the change surface.

Before finishing any `ops/` edit:

1. Check whether the change adds, removes, or reshapes any documented ops feature, including:
   - new or removed playbooks in `ops/*.yml`
   - new or removed roles in `ops/roles/`
   - new or removed Ansible tags
   - meaningful flow changes in existing playbooks or roles
2. Update `ops/FEATURES.md` when the docs should change.
3. Run the local guard:
   - from repo root: `python3 ops/bin/check_features_sync.py`
   - or from `ops/`: `python3 bin/check_features_sync.py`
4. If the guard fails, fix `ops/FEATURES.md` before ending your turn.

## Scope

Apply this guard only to changes in `ops/`. Do not require it for unrelated parts of the repository.

## What the guard checks

`ops/bin/check_features_sync.py` verifies that `ops/FEATURES.md` stays in sync with:

- Ansible tags found in `ops/*.yml` and `ops/roles/**/*.yml`
- playbooks in `ops/*.yml`
- role directories in `ops/roles/`

## Final response expectation

If you changed anything under `ops/`, mention whether you updated `ops/FEATURES.md` and whether you ran `ops/bin/check_features_sync.py`.
