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

## Local Ansible command preferences

When suggesting Ansible commands for work in `ops/`, use these local defaults unless the user says otherwise:

- assume commands are run from the `ops/` directory
- use the user's `apb` alias instead of `ansible-playbook`
- prefer `-t` instead of `--tags`
- prefer `-l` to limit execution to a specific host when that is the tighter control
- do not add the `ai_server` or `repo_server` play tags when a host limit plus a narrower role/task tag is sufficient

Example:

- prefer `apb setup_epytype.yml -l gex0 -t pull_models`
- avoid `apb setup_epytype.yml -t ai_server,pull_models` unless the broader play selection is specifically needed

## Ansible debug list formatting preference

For human-readable Ansible debug output that prints lists or line-oriented command results:

- prefer a YAML block scalar `msg: |`
- render one entry per line
- avoid Python list rendering such as `['a', 'b']`
- avoid `join('\n')` when it results in literal escaped `\n` in callback output
- prefer a Jinja loop inside the block scalar so the terminal shows real line breaks

Preferred pattern:

```yaml
- debug:
    msg: |
      Heading:
      {% for line in some_lines %}
      {{ line }}
      {% endfor %}
```
