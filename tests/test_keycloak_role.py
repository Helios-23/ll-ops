"""Local render and lifecycle checks for the dedicated Keycloak stack."""
import json
import os
import shutil
from pathlib import Path
import ssl
import subprocess
import tempfile
import time
import unittest
import urllib.parse
import urllib.request
import uuid

import jinja2
import yaml

ROOT = Path(__file__).resolve().parents[1]
ROLE = ROOT / 'roles/keycloak'


def render_stack(directory):
    values = yaml.safe_load((ROLE / 'defaults/main.yml').read_text())
    values.update(keycloak_directory=str(directory), keycloak_tls_directory=str(directory / 'tls'),
                  keycloak_hostname='https://localhost:18443', keycloak_https_port=18443,
                  keycloak_admin_user='ll-admin',
                  keycloak_credentials={'admin_password': uuid.uuid4().hex,
                                        'database_password': uuid.uuid4().hex})
    environment = jinja2.Environment(undefined=jinja2.StrictUndefined)
    environment.filters['to_json'] = json.dumps
    for template in (ROLE / 'templates').glob('*.j2'):
        (directory / template.name.removesuffix('.j2')).write_text(
            environment.from_string(template.read_text()).render(values))
    return values


class KeycloakRoleTests(unittest.TestCase):
    def test_secure_render_and_service_lifecycle_contract(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            values = render_stack(directory)
            stack = yaml.safe_load((directory / 'compose.yml').read_text())
            database = stack['services']['database']
            server = stack['services']['keycloak']
            self.assertEqual(database['mem_limit'], '512m')
            self.assertEqual(server['mem_limit'], '1536m')
            self.assertNotIn('ports', database)
            self.assertTrue(stack['networks']['database']['internal'])
            self.assertEqual(server['ports'], ['127.0.0.1:18443:8443'])
            for service in stack['services'].values():
                self.assertEqual(service['pull_policy'], 'never')
                self.assertIn('@sha256:', service['image'])
            self.assertEqual(server['depends_on']['database']['condition'], 'service_healthy')
            self.assertIn('KC_BOOTSTRAP_ADMIN_USERNAME=ll-admin', (directory / 'keycloak.env').read_text())
            self.assertNotIn(values['keycloak_credentials']['admin_password'],
                             (directory / 'postgres.env').read_text())
            unit = (directory / 'keycloak.service').read_text()
            self.assertIn('WantedBy=multi-user.target', unit)
            self.assertIn('--wait --wait-timeout', unit)
            self.assertIn(' down --timeout', unit)
            self.assertNotIn('--volumes', unit)
            subprocess.run(['docker', 'compose', '-f', str(directory / 'compose.yml'),
                            'config', '--quiet'], check=True)

    @unittest.skipUnless(shutil.which('ansible-playbook'), 'Requires the existing Ansible environment')
    def test_vault_preflight_rejects_unsafe_passwords_without_logging_values(self):
        (ROOT / 'dist').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='keycloak-vault-check-', dir=ROOT / 'dist') as temporary:
            directory = Path(temporary).resolve()
            inventory = directory / 'inventory.yml'
            inventory.write_text(yaml.safe_dump({'all': {'hosts': {
                'keycloak_preflight_local': {'ansible_connection': 'local'}}}}))
            play = directory / 'preflight.yml'
            play.write_text(yaml.safe_dump([{'hosts': 'all', 'gather_facts': False, 'become': False,
                'tasks': [{'ansible.builtin.include_role': {
                    'name': str(ROLE), 'tasks_from': 'preflight'}}]}]))
            password = uuid.uuid4().hex + uuid.uuid4().hex
            cases = [('valid', password, uuid.uuid4().hex, 0),
                     ('missing', '', uuid.uuid4().hex, 2),
                     ('same', password, password, 2),
                     ('interpolation', password, '${UNSAFE}' * 8, 2)]
            for label, admin, database, expected in cases:
                with self.subTest(label=label):
                    values = directory / 'values.yml'
                    values.write_text(yaml.safe_dump({
                        'keycloak_hostname': 'https://identity.qa.example.com:8443',
                        'keycloak_admin_password': admin, 'keycloak_database_password': database}))
                    values.chmod(0o600)
                    result = subprocess.run(['ansible-playbook', str(play), '-i', str(inventory),
                                             '--check', '-e', '@' + str(values)],
                                            capture_output=True, text=True, cwd=ROOT)
                    self.assertEqual(result.returncode, expected, 'Unexpected password validation result')
                    for secret in (admin, database):
                        if secret:
                            self.assertNotIn(secret, result.stdout + result.stderr)

    @unittest.skipUnless(os.environ.get('KEYCLOAK_DOCKER_TEST') == '1',
                         'Set KEYCLOAK_DOCKER_TEST=1 for real local container acceptance')
    def test_https_admin_account_survives_compose_stop_start(self):
        work = ROOT / 'dist'
        work.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='keycloak-check-', dir=work) as temporary:
            directory = Path(temporary).resolve()
            directory.chmod(0o755)
            values = render_stack(directory)
            tls = directory / 'tls'
            tls.mkdir()
            subprocess.run(['openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
                            '-keyout', str(tls / 'privkey.pem'), '-out', str(tls / 'fullchain.pem'),
                            '-days', '1', '-subj', '/CN=localhost', '-addext', 'subjectAltName=DNS:localhost'],
                           check=True, capture_output=True)
            # Test-only ephemeral key, readable by the container UID. Never used on QA.
            (tls / 'privkey.pem').chmod(0o644)
            project = 'keycloak-check-' + uuid.uuid4().hex[:10]
            command = ['docker', 'compose', '-p', project, '-f', str(directory / 'compose.yml')]
            context = ssl.create_default_context(cafile=str(tls / 'fullchain.pem'))

            def request(path, data=None, token=None, method=None):
                headers = {'Authorization': 'Bearer ' + token} if token else {}
                if isinstance(data, dict):
                    data = json.dumps(data).encode()
                    headers['Content-Type'] = 'application/json'
                req = urllib.request.Request('https://localhost:18443' + path, data=data,
                                             headers=headers, method=method)
                with urllib.request.urlopen(req, context=context, timeout=15) as response:
                    content = response.read()
                    return json.loads(content) if content else None

            def login():
                return request('/realms/master/protocol/openid-connect/token', urllib.parse.urlencode({
                    'client_id': 'admin-cli', 'grant_type': 'password', 'username': values['keycloak_admin_user'],
                    'password': values['keycloak_credentials']['admin_password']}).encode())['access_token']

            try:
                subprocess.run(command + ['up', '-d', '--wait', '--wait-timeout', '240', '--pull', 'never'], check=True)
                for _ in range(2):
                    discovery = request('/realms/master/.well-known/openid-configuration')
                    self.assertEqual(discovery['issuer'], 'https://localhost:18443/realms/master')
                    time.sleep(1)
                token = login()
                request('/admin/realms', {'realm': 'persistence-check', 'enabled': True}, token)
                request('/admin/realms/persistence-check/users',
                        {'username': 'persistent-user', 'enabled': True}, token)
                subprocess.run(command + ['down', '--timeout', '60'], check=True)
                subprocess.run(command + ['up', '-d', '--wait', '--wait-timeout', '240', '--pull', 'never'], check=True)
                users = request('/admin/realms/persistence-check/users?username=persistent-user', token=login())
                self.assertEqual([user['username'] for user in users], ['persistent-user'])
            finally:
                # Only this uniquely named test project owns these disposable volumes.
                subprocess.run(command + ['down', '--volumes', '--timeout', '60'], check=True)


if __name__ == '__main__':
    unittest.main()
