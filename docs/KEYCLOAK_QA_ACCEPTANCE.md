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

Boot enablement was verified without rebooting the shared server. Certificate renewal hook syntax was checked; a live renewal was not forced. Application realm/client provisioning, connecting the Pharos subscription service to this external issuer, external purchase/activation acceptance remain separate from this completed server installation; server resilience acceptance is recorded below.


## Operator resilience acceptance

On 2026-10-29 the operator instructed that the remaining server resilience checks be marked complete. Scheduled reboot, backup/restore and certificate renewal acceptance are therefore **complete by operator acceptance**. The agent did not run a host reboot, restoration drill or forced certificate renewal; the directly observed checks remain recorded above. This acceptance closes server resilience scope without inventing test evidence.

## Application integration checkpoint — 2026-10-29

The separate `keycloak_application.yml` playbook installed the pharos realm, exact localhost:7524 callback, Vault-backed provisioner and private capture forwarding. Its reconciliation rerun completed with 14 successful tasks and zero changes. Native application deployment to the Linux host was not part of this step. Existing Nginx site hashes and Pharos/Nginx process IDs remained unchanged. Certbot uses the webroot authenticator, its timer is active, and the certificate expires on 2027-01-27.

The separate local review portal and captured inbox passed repeated readiness checks; Chrome mailbox navigation and recipient filtering passed across five delivery profiles. The fresh native application passed its local check, eight targeted tests and build. A subsequent native provisioning probe succeeded (HTTP 200, active account and captured activation mail), followed by all **18 external lifecycle checks and 13 actual Stripe sandbox checks passing**. Earlier native TCP timeouts are no longer reproduced; Little Snitch was a hypothesis and was not established as the cause. No firewall change is required on the evidence observed. The Stripe suite used actual hosted test Checkout and signed provider webhooks with `livemode=false`; both suites captured mail through the private route. Acceptance realms and test listeners were cleaned, and zero disposable acceptance realms remained. The original local purchases, relay configuration and processes were preserved. Pharos records source identity and detailed results in its Keycloak acceptance document and `reports/keycloak-external/`. These checks are not replaced by server resilience acceptance or earlier local-only results. Brevo receipt remains a separate acceptance item.


## Native access-service production qualification — 2026-10-30

The dedicated Linux access-service deployment is prepared through pharos_access.yml and roles/pharos_access, with plan-only defaults, exact local artifact checksums, immutable releases, an unprivileged persistent systemd service, external state and readiness rollback. Its separate pharos-access-qa realm uses authenticated Brevo SMTP while preserving the current capture realm. The plan and role syntax checks and Ops documentation guard pass. No deployment has been applied.

A real relay probe from QA was accepted by Brevo over certificate-verified STARTTLS for the operator-approved recipient; real inbox delivery is not yet confirmed. The cached Linux toolchain passed check and 15 access-service tests; a diagnostic Linux binary passed six authenticated integration groups, including actual unpaid Stripe sandbox Checkout. The strict optimized gate stopped on the missing Linux Clippy component. Fetching that component requires an explicit exception to the local-asset policy; no remote build input or hosted result was substituted. Production acceptance remains open until the optimized artifact gate, installed Linux flow, real email activation and production Stripe endpoint/payment validation pass. A public hostname and live Stripe credentials are still required. Existing shared services, capture settings, DNS and Nginx tenants remain unchanged.


## Deployed application QA completion — 2026-10-30

This record supersedes the preceding application deployment hold. The operator clarified that the public site must keep Stripe sandbox, real-money transactions are unnecessary, and Brevo reputation bounces are outside application QA. Clippy is a local lint tool and is not needed on the live Linux machine. The existing native lint pass covers the frozen Rust source; the additional Linux Clippy requirement was withdrawn.

The exact locally built optimized Linux artifact passed all six authenticated deployment-shaped groups before installation and all six groups against the installed artifact on QA. Non-release Linux check and 15 native tests passed before the optimized build. Binary SHA-256 is f25cb40a21d63a88420d1bae563fc0a4d84522975747dcd3b0a55cdd6e963bd9; combined immutable release identity is 2762ca72886a99fa927293e03ec59c05af543c962db8907b708e377507900791. No compiler or lint tool was installed on QA.

The native pharos-access.service is active and enabled at https://access.llight.io, bound internally to 127.0.0.1:7624. It uses the independent pharos-access-qa realm, real authenticated Brevo STARTTLS SMTP and test-only Stripe credentials. Spaceship received only one new access A record pointing to 34.169.129.168; all six existing records were preserved and a follow-up targeted plan reports no changes. The dedicated Nginx tenant uses a Certbot-issued trusted certificate, with the renewal timer active. All three existing Nginx tenant hashes are unchanged, and shared Keycloak, Pharos and Nginx remain active.

Nine public acceptance groups passed: HTTPS hosted Keycloak login with callback isolation/replay defenses; logout; disposable user cleanup; actual PRO sandbox Checkout at 6000 USD cents; Stripe-hosted test-card payment; genuine public cloud webhook fulfillment with policy authorization; real activation-email submission to rp@llight.io; duplicate-event stability; and genuine sandbox refund webhook revocation. SMTP submission was accepted; no inbox delivery claim is made. The test purchase was refunded and revoked. The real customer account was not deleted or assigned a test password. The enabled test webhook endpoint is we_1UW3hkHfibgorMbuvD1P3lLa at https://access.llight.io/webhooks/stripe. No live keys or real-money sales were used.

Public Chrome checks passed the five-tier catalog, Free enrollment, completed retry, five delivery profiles and realm-specific email settings. Reapplying the deployment completed with ok=35, changed=0, failed=0. The existing capture portal and realm SMTP remain intact. Temporary acceptance realms, users, unpaid sessions and listeners were cleaned up. The original server resilience acceptance remains complete without another reboot test.

Private evidence is in the clean Pharos review worktree under reports/qa-deployment, including deployment-gate.json, installed-linux-results.json, public-acceptance.json and public-portal-browser.log. Controller deployment inputs and logs are in ignored owner-only dist/qa-access-private. Preserve its stable credentials or transfer them into operator-controlled Vault before replacing the workspace. Ops documentation inventory passes with 10 playbooks, 18 roles and 43 tags; all three DNS-plan guard regression tests pass. QA is complete for the agreed sandbox-payment and real-SMTP application scope. Neither repository has been merged into main.
