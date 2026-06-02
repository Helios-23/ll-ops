# epytype_release

Prepares an Epytype release from the local checkout and pushes `HEAD:release`
to Forgejo and GitHub. The Forgejo release workflow publishes release assets to
GitHub when its repository secrets and variables are configured.

Run from `ops/`:

```bash
ansible-playbook github-release.yml
```

Tag selection:

```bash
ansible-playbook github-release.yml
ansible-playbook github-release.yml -t epytype
ansible-playbook github-release.yml -t lantern
```

With no tags, the playbook runs both release plays. `-t epytype` runs only the
Epytype release play. `-t lantern` runs only the Lantern release play.

By default the role composes the final version from separate major, minor, and
release-number components. Users normally edit `epytype_release_major_version`
and `epytype_release_minor_version` by hand. If either changes from the current
release policy version, the release number resets to `0`; otherwise it
increments by one. For example, current `0.7.6` with minor set to `8` becomes
`0.8.0`.

To publish an initial prepared release such as `0.7.0` without incrementing,
set the release number explicitly:

```bash
ansible-playbook github-release.yml \
  -e epytype_release_number=0
```

Use an explicit version only when needed:

```bash
ansible-playbook github-release.yml \
  -e epytype_release_version=0.1.1
```

Useful variables:

- `epytype_release_major_version`: major version component
- `epytype_release_minor_version`: minor version component
- `epytype_release_number`: optional explicit release/patch component
- `epytype_release_version`: explicit `x.y.z` version; overrides bumping
- `epytype_release_repo_dir`: local Epytype repo path
- `epytype_release_run_checks`: run local release checks before committing
- `epytype_release_push`: push `HEAD:release` after committing
- `epytype_release_github_repo`: GitHub `owner/repo` used for README CI link and GitHub push
- `epytype_release_push_github`: push `release` and the release tag to GitHub
- `epytype_release_allow_dirty`: allow starting from a dirty working tree

The Lantern play reuses the same role with repo-specific overrides. Set
`lantern_release_github_repo` in `github-release.yml` to the target GitHub
`owner/repo` when Lantern should mirror releases there.

The GitHub mirror excludes `docs/release-automation.md` for both Epytype and
Lantern, so that file remains Forgejo-only even when the release branch, tag,
and GitHub release asset are published.
