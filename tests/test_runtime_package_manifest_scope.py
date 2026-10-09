"""Exercise the deployed role's manifest selection with package-owned paths."""
from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]


class RuntimePackageManifestScopeTests(unittest.TestCase):
    def test_services_stop_before_installation_and_staged_migrations(self):
        for role, stop, mutation, variable in [
            ('pharos_deploy', 'Stop existing Pharos services before runtime package installation', 'Install Pharos package from staged repository', 'pharos_deploy_services'),
            ('pharos_app_deploy', 'Stop existing Pharos services before app migration and promotion', 'Apply staged {{ app_id }} migrations for dynamic app runtime', 'pharos_app_deploy_services'),
        ]:
            tasks = yaml.safe_load((ROOT / 'roles' / role / 'tasks/main.yml').read_text())
            names = [task.get('name') for task in tasks]
            self.assertLess(names.index(stop), names.index(mutation))
            task = tasks[names.index(stop)]
            self.assertEqual(task['ansible.builtin.systemd']['state'], 'stopped')
            self.assertEqual(task['loop'], '{{ ' + variable + ' | reverse | list }}')
            self.assertEqual(task['when'], 'item in ansible_facts.services')
            self.assertTrue(any('ansible.builtin.service_facts' in earlier for earlier in tasks[:names.index(stop)]))

    def test_external_and_nested_apps_are_not_runtime_migration_targets(self):
        tasks = yaml.safe_load((ROOT / 'roles/pharos_deploy/tasks/main.yml').read_text())
        inventory = next(t for t in tasks if t['name'] == 'Read the installed runtime package file inventory')
        self.assertEqual(inventory['ansible.builtin.command']['argv'], ['dpkg-query', '--listfiles', 'pharos'])
        select = next(t for t in tasks if t['name'] == 'Select manifests owned by the installed runtime package')
        play = [{'hosts': 'localhost', 'gather_facts': False, 'become': False, 'vars': {
            'pharos_deploy_preserve_existing_apps': False,
            'pharos_deploy_packaged_apps': [{'app_id': 'stale_external'}],
            'pharos_deploy_package_files': {'stdout_lines': [
                '/srv/pharos/apps/todo_list/pharos.app.json',
                '/srv/pharos/apps/commerce_spa/pharos.app.json',
                '/usr/share/pharos/examples/architect/pharos.app.json',
                '/srv/pharos/apps/commerce_spa/generated/other/pharos.app.json',
                '/srv/pharos/apps/static_app/static/index.html',
            ]},
        }, 'tasks': [select, {'ansible.builtin.assert': {'that': [
            "pharos_deploy_packaged_manifest_paths == ['/srv/pharos/apps/todo_list/pharos.app.json', '/srv/pharos/apps/commerce_spa/pharos.app.json']",
            'pharos_deploy_packaged_apps == []',
        ]}}]}]
        (ROOT / 'tmp').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='manifest-scope-', dir=ROOT / 'tmp') as work:
            path = Path(work) / 'proof.yml'
            path.write_text(yaml.safe_dump(play, sort_keys=False))
            result = subprocess.run([shutil.which('ansible-playbook') or 'ansible-playbook', '-i', 'localhost,', '-c', 'local', str(path)], cwd=ROOT, capture_output=True, text=True, timeout=60)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
