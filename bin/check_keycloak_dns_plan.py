#!/usr/bin/env python3
"""Reject any Terraform plan that does more than add one declared authentication or access A record."""
import argparse
from collections import Counter
import json


def check(plan, address, name='auth'):
    if name not in ('auth', 'access'):
        raise ValueError('Only the declared authentication or access host may be added')
    changes = [r for r in plan.get('resource_changes', [])
               if r['mode'] == 'managed' and r['change']['actions'] != ['no-op']]
    if len(changes) != 1 or changes[0]['address'] != 'spaceship_dns_records.root':
        raise ValueError('Expected only the existing Spaceship DNS resource to change')
    change = changes[0]['change']
    if change['actions'] != ['update']:
        raise ValueError('DNS replacement or deletion is forbidden')
    before, after = change['before'], change['after']
    if before['domain'] != 'llight.io' or after['domain'] != before['domain']:
        raise ValueError('DNS domain must remain llight.io')

    def records(value):
        return Counter(json.dumps({k: v for k, v in record.items() if v is not None},
                                  sort_keys=True) for record in value['records'])

    old, new = records(before), records(after)
    additions = list((new - old).elements())
    if old - new or len(additions) != 1:
        raise ValueError('Existing records must remain identical; only one addition is allowed')
    added = json.loads(additions[0])
    if added != {'type': 'A', 'name': name, 'address': address, 'ttl': 3600}:
        raise ValueError('Unexpected added DNS record')
    return len(list(old.elements()))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('plan_json')
    parser.add_argument('--address', required=True)
    parser.add_argument('--name', choices=['auth', 'access'], default='auth')
    args = parser.parse_args()
    with open(args.plan_json) as source:
        count = check(json.load(source), args.address, args.name)
    print(f'Plan accepted: preserve all {count} existing records; add only {args.name} A {args.address}')
