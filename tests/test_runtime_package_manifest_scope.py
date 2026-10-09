"""Exercise the deployed role's manifest selection with package-owned paths."""
from __future__ import annotations

import shutil
import base64
import copy
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]


class RuntimePackageManifestScopeTests(unittest.TestCase):
    def test_staged_apps_preserve_all_configured_backend_connections(self):
        tasks = yaml.safe_load((ROOT / 'roles/pharos_app_deploy/tasks/main.yml').read_text())
        preserve = next(t for t in tasks if t['name'] == 'Preserve configured database authority in the staged app')
        self.assertLess(tasks.index(preserve), next(i for i, t in enumerate(tasks) if t['name'] == 'Apply staged {{ app_id }} migrations for dynamic app runtime'))
        self.assertTrue(preserve['no_log'])
        (ROOT / 'tmp').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='connection-preservation-', dir=ROOT / 'tmp') as work:
            plays = []
            for backend in ('sqlite', 'postgresql', 'mysql', 'mongodb'):
                stage = Path(work) / backend
                stage.mkdir()
                old = f'db_backend={backend}\ndb_path=/operator/retained.sqlite3\ndb_name=retained_app\ndb_options=option=a=b\ndb_password_env=OPERATOR_DATABASE_PASSWORD\n'
                new = 'base_path=/app\ndb_backend=sqlite\ndb_path=/incorrect/global.sqlite3\ndb_name=incorrect_global\ndb_options=incorrect\ndb_tls_mode=require\nqueue_enabled=1\n'
                (stage / 'app.conf').write_text(new)
                task = copy.deepcopy(preserve)
                task['ansible.builtin.copy'].pop('owner')
                task['ansible.builtin.copy'].pop('group')
                plays.append({'hosts': 'localhost', 'gather_facts': False, 'become': False, 'vars': {
                    'app_id': backend,
                    'pharos_app_deploy_remote_stage_dir': str(stage),
                    'pharos_app_deploy_existing_config': {'stat': {'exists': True}},
                    'pharos_app_deploy_staged_config': {'stat': {'exists': True}},
                    'pharos_app_deploy_existing_config_raw': {'content': base64.b64encode(old.encode()).decode()},
                    'pharos_app_deploy_new_config_raw': {'content': base64.b64encode(new.encode()).decode()},
                }, 'tasks': [task]})
            path = Path(work) / 'proof.yml'
            path.write_text(yaml.safe_dump(plays, sort_keys=False))
            result = subprocess.run([shutil.which('ansible-playbook') or 'ansible-playbook', '-i', 'localhost,', '-c', 'local', str(path)], cwd=ROOT, capture_output=True, text=True, timeout=60)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            for backend in ('sqlite', 'postgresql', 'mysql', 'mongodb'):
                lines = (Path(work) / backend / 'app.conf').read_text().splitlines()
                self.assertEqual(len(lines), len(set(line.split('=', 1)[0] for line in lines)))
                values = dict(line.split('=', 1) for line in lines)
                self.assertEqual(values['db_backend'], backend)
                self.assertEqual(values['db_path'], '/operator/retained.sqlite3')
                self.assertEqual(values['db_name'], 'retained_app')
                self.assertEqual(values['db_options'], 'option=a=b')
                self.assertEqual(values['db_password_env'], 'OPERATOR_DATABASE_PASSWORD')
                self.assertEqual(values['db_tls_mode'], 'require')
                self.assertEqual(values['queue_enabled'], '1')

    def test_operator_configs_are_retained_before_package_migrations(self):
        tasks = yaml.safe_load((ROOT / 'roles/pharos_deploy/tasks/main.yml').read_text())
        self.assertEqual(tasks[0]['name'], 'Require runtime deployment configuration before changing services')
        install = next(t for t in tasks if t['name'] == 'Install Pharos package from staged repository')
        self.assertIn('--force-confold', install['shell'])
        self.assertNotIn('--force-confnew', install['shell'])
        paths = (ROOT.parent / 'pharos/cross/packaging/debian/conffiles').read_text().splitlines()
        for app in ('todo_list', 'commerce_spa', 'dynamic_app', 'static_app'):
            self.assertIn(f'/srv/pharos/apps/{app}/app.conf', paths)

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
