#!/usr/bin/env python3
"""Apply one declared subscription realm without disclosing credentials or tokens."""
import argparse
import json
from pathlib import Path
from urllib import request, parse, error

ORIGIN = 'https://auth.llight.io'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--admin-user', required=True)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    credentials = json.loads(Path('/opt/keycloak/credentials.json').read_text())
    desired = json.loads(Path('/opt/keycloak/pharos-realm.json').read_text())
    if desired.get('realm') != 'pharos':
        raise RuntimeError('Only the declared pharos subscription realm may be managed')
    token = None

    def call(path, value=None, method='GET'):
        payload = json.dumps(value).encode() if value is not None else None
        headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token}
        with request.urlopen(request.Request(ORIGIN + '/admin/' + path, data=payload, headers=headers, method=method), timeout=30) as response:
            body = response.read()
            return json.loads(body) if body else None

    data = parse.urlencode({'client_id': 'admin-cli', 'grant_type': 'password', 'username': args.admin_user,
                            'password': credentials['admin_password']}).encode()
    with request.urlopen(request.Request(ORIGIN + '/realms/master/protocol/openid-connect/token', data=data), timeout=20) as response:
        session = json.load(response)
        token = session['access_token']
    try:
        current = call('realms/pharos')
    except error.HTTPError as failure:
        if failure.code != 404:
            raise
        if not args.check:
            call('realms', desired, 'POST')
        print('changed: created subscription realm and scoped clients')
        return
    # Preserve identities, keys, password/session state and unrelated realm configuration.
    fields = ('enabled', 'sslRequired', 'registrationAllowed', 'verifyEmail', 'resetPasswordAllowed', 'bruteForceProtected', 'smtpServer')
    def smtp(value):
        # Keycloak omits empty values and masks passwords in its read representation.
        return {key: item for key, item in value.items() if item not in ('', None)
                and not (value.get('auth') == 'false' and key in ('user', 'password'))}

    updates = {key: desired[key] for key in fields if
               (smtp(current.get(key, {})) != smtp(desired[key]) if key == 'smtpServer'
                else current.get(key) != desired[key])}
    changes = ['realm.' + key for key in updates]
    changed = bool(updates)
    if updates and not args.check:
        call('realms/pharos', updates, 'PUT')
    for client in desired['clients']:
        found = call('realms/pharos/clients?' + parse.urlencode({'clientId': client['clientId']}))
        if not found:
            raise RuntimeError('Existing realm is missing an expected client; refuse an implicit client recreation')
        existing = call('realms/pharos/clients/' + found[0]['id'])
        selected = {}
        for key, value in client.items():
            if key == 'secret':
                continue
            actual = existing.get(key)
            if key == 'attributes':
                if any((actual or {}).get(name) != item for name, item in value.items()):
                    selected[key] = dict(actual or {}, **value)
            elif key == 'webOrigins' and value == []:
                # Keycloak derives exact callback origins when the configured list is empty.
                derived = {parse.urlsplit(uri).scheme + '://' + parse.urlsplit(uri).netloc
                           for uri in client.get('redirectUris', [])}
                if set(actual or []) not in (set(), derived):
                    selected[key] = value
            elif isinstance(value, list):
                if (actual or []) != value:
                    selected[key] = value
            elif actual != value:
                selected[key] = value
        if client.get('secret'):
            actual = call('realms/pharos/clients/' + found[0]['id'] + '/client-secret')['value']
            if actual != client['secret']:
                raise RuntimeError('Provisioner secret mismatch; explicit rotation required')
        if selected:
            changes.extend('client.' + client['clientId'] + '.' + key for key in selected)
            if not args.check:
                call('realms/pharos/clients/' + found[0]['id'], selected, 'PUT')
            changed = True
    print('changed: ' + ', '.join(changes) if changed else 'unchanged: subscription realm and clients already match')


if __name__ == '__main__':
    main()
