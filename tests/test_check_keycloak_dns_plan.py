import copy
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('dns_plan', Path(__file__).resolve().parents[1] / 'bin/check_keycloak_dns_plan.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DnsPlanTests(unittest.TestCase):
    def setUp(self):
        self.old = [{'type': 'A', 'name': '@', 'ttl': 3600, 'address': '34.169.129.168'}]
        self.new = copy.deepcopy(self.old) + [{'type': 'A', 'name': 'auth', 'ttl': 3600, 'address': '34.169.129.168'}]
        self.plan = {'resource_changes': [{'address': 'spaceship_dns_records.root', 'mode': 'managed',
            'change': {'actions': ['update'], 'before': {'domain': 'llight.io', 'records': self.old},
                       'after': {'domain': 'llight.io', 'records': self.new}}}]}

    def test_only_auth_addition_is_accepted(self):
        self.assertEqual(module.check(self.plan, '34.169.129.168'), 1)

    def test_access_requires_explicit_selection_and_preserves_existing_records(self):
        self.plan['resource_changes'][0]['change']['after']['records'][-1]['name'] = 'access'
        self.assertEqual(module.check(self.plan, '34.169.129.168', 'access'), 1)
        with self.assertRaises(ValueError):
            module.check(self.plan, '34.169.129.168')
        self.plan['resource_changes'][0]['change']['after']['records'][0]['ttl'] = 60
        with self.assertRaises(ValueError):
            module.check(self.plan, '34.169.129.168', 'access')

    def test_removal_modification_and_server_changes_are_rejected(self):
        for case in ['remove', 'modify', 'server', 'replace', 'wrong_ip']:
            with self.subTest(case=case):
                plan = copy.deepcopy(self.plan)
                change = plan['resource_changes'][0]['change']
                if case == 'remove':
                    change['after']['records'].pop(0)
                elif case == 'modify':
                    change['after']['records'][0]['ttl'] = 60
                elif case == 'server':
                    plan['resource_changes'].append({'address': 'google_compute_instance.pharos',
                        'mode': 'managed', 'change': {'actions': ['update']}})
                elif case == 'replace':
                    change['actions'] = ['delete', 'create']
                else:
                    change['after']['records'][-1]['address'] = '192.0.2.1'
                with self.assertRaises(ValueError):
                    module.check(plan, '34.169.129.168')
