# Keycloak shared-host installation acceptance

Validated on 2026-10-29 against `web0` (`34.169.129.168`), the operator-confirmed shared QA/production server. This report covers the identity server, DNS and Nginx tenant installation.

## Installed configuration

- Public origin: https://auth.llight.io
- Admin console: https://auth.llight.io/admin/master/console/
- Administrator: `ll-admin`, read directly from `keycloak_admin_user`.
- Password sources: `vault.keycloak.admin_pass` and `vault.keycloak.db_pass`; no values are included in this report.
- Docker and `keycloak.service` active and enabled at boot; Keycloak 26.8.1 and PostgreSQL 16 use the pinned, locally transferred images.
- Certificate-verified Nginx HTTPS upstream at `127.0.0.1:8443`; PostgreSQL and the management port remain unpublished.
- Persistent named PostgreSQL volume: `keycloak_database`.
- Logs: `journalctl -u keycloak.service`, Compose project `keycloak`, and `/var/log/nginx/keycloak.access.log` / `keycloak.error.log`.

## Validation results

| Check | Result |
| --- | --- |
| Local Keycloak render, trusted HTTPS login as configured user, account persistence after Compose stop/start, Vault validation | Three tests passed; the direct canonical-user template also passed subsequent render and Vault checks |
| DNS plan safety tests | Two tests passed, including rejection of record deletion/modification, server updates, resource replacement and wrong destination |
| Terraform | Local validate and changed-file format checks passed; reviewed saved DNS-only plan applied |
| Live Spaceship records | Five original custom records remained identical; only `A auth 34.169.129.168`, TTL 3600, was added; refreshed targeted plan had no changes |
| Public HTTPS | Trusted certificate, admin console HTTP 200, discovery HTTP 200 and exact issuer `https://auth.llight.io/realms/master` |
| Administrator authentication | Real token grant and Admin API lookup confirmed enabled `ll-admin` account |
| Service persistence | Created disposable realm/account; stopped Keycloak; database volume retained; started Keycloak; authenticated and verified the same account persisted |
| Acceptance cleanup | Disposable realm and private test state removed |
| Isolation | Existing Pharos page returned HTTP 200 during setup and while Keycloak was stopped |
| Existing processes | Pharos PID 23851 and Nginx master PID 32387 unchanged across the rollout |
| Existing Nginx sites | Both original file SHA-256 hashes unchanged (below) |
| Idempotence | Full final playbook rerun: 44 successful tasks, zero changes, zero failures |
| Automation guards | Ansible syntax/lint, renewal-hook shell syntax, docs sync and diff whitespace checks passed |

Original Nginx file hashes, verified unchanged after deployment:

```text
f570631aa69f97f9089f1209a81327389bed04a038f82d359e1b9108ee8de13f  /etc/nginx/sites-enabled/default-http
acc0223b18eaac2db4785396c389621684e1c585a780e00306ec291ee98c4593  /etc/nginx/sites-enabled/pharos.llight.io.conf
```

Boot enablement was verified without rebooting the shared server. Certificate renewal hook syntax was checked; a live renewal was not forced. Application realm/client provisioning, connecting the Pharos subscription service to this external issuer, external purchase/activation acceptance and backup restoration remain separate from this completed server installation.
