#!/usr/bin/env python3
"""Validate the deployed auth tenant without printing credentials or tokens."""
import argparse
import json
import os
import re
from pathlib import Path
import secrets
import ssl
import urllib.parse
import urllib.request

ORIGIN = 'https://auth.llight.io'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['inspect', 'create', 'verify', 'cleanup'])
    parser.add_argument('--admin-user', default='ll-admin')
    args = parser.parse_args()
    credentials = json.loads(Path('/opt/keycloak/credentials.json').read_text())
    state = Path('/opt/keycloak/qa-acceptance-state.json')
    context = ssl.create_default_context()

    def request(path, data=None, token=None, method=None):
        headers = {'Authorization': 'Bearer ' + token} if token else {}
        if isinstance(data, dict):
            data = json.dumps(data).encode()
            headers['Content-Type'] = 'application/json'
        req = urllib.request.Request(ORIGIN + path, data=data, headers=headers, method=method)
        with urllib.request.urlopen(req, context=context, timeout=20) as response:
            content = response.read()
            return json.loads(content) if content else None

    discovery = request('/realms/master/.well-known/openid-configuration')
    assert discovery['issuer'] == ORIGIN + '/realms/master', 'Unexpected issuer'
    token = request('/realms/master/protocol/openid-connect/token', urllib.parse.urlencode({
        'client_id': 'admin-cli', 'grant_type': 'password', 'username': args.admin_user,
        'password': credentials['admin_password']}).encode())['access_token']
    users = request('/admin/realms/master/users?' + urllib.parse.urlencode({
        'username': args.admin_user, 'exact': 'true'}), token=token)
    assert len(users) == 1 and users[0]['username'] == args.admin_user and users[0]['enabled']
    print('Verified trusted HTTPS, fixed public OIDC issuer, and configured administrator login')
    if args.action == 'inspect':
        return
    if args.action == 'create':
        record = {'realm': 'qa-persistence-' + secrets.token_hex(8), 'username': 'qa-persistent-user'}
        descriptor = os.open(state, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(descriptor, 'w') as output:
            json.dump(record, output)
        request('/admin/realms', {'realm': record['realm'], 'enabled': True}, token=token)
        request('/admin/realms/' + record['realm'] + '/users', {
            'username': record['username'], 'enabled': True}, token=token)
        print('Created isolated disposable realm and account for service persistence validation')
        return
    record = json.loads(state.read_text())
    assert re.fullmatch(r'qa-persistence-[0-9a-f]{16}', record['realm'])
    if args.action == 'cleanup':
        request('/admin/realms/' + record['realm'], token=token, method='DELETE')
        state.unlink()
        print('Removed only the disposable acceptance realm and local test state')
        return
    users = request('/admin/realms/' + record['realm'] + '/users?' + urllib.parse.urlencode({
        'username': record['username'], 'exact': 'true'}), token=token)
    assert len(users) == 1 and users[0]['username'] == record['username'], 'Account did not persist'
    print('Verified the isolated test account persisted')


if __name__ == '__main__':
    main()
