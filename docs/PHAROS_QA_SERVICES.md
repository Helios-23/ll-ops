# Pharos QA scanner and database services

`pharos_services.yml` prepares two isolated Docker Compose projects on `web0`. It defaults to a plan and changes services only with `pharos_services_apply=true`. It does not deploy a Pharos package or app, edit runtime/app configuration, transfer database contents, or touch the Keycloak database.

## Capacity and persistence

Require at least 3 GiB of free root-disk space and 3.8 GiB total RAM. Inspect filesystem and memory capacity before staging archives; container images, signature updates, database growth and logs need working space. A full host is a prerequisite failure. Obtain separate approval for an in-place cloud-disk enlargement; never replace the instance or erase retained data to satisfy this guard.

| Service | Host binding | Persistent storage | Resource ceiling |
| --- | --- | --- | --- |
| ClamAV | `127.0.0.1:3310` | `/var/lib/pharos-clamav`, `/var/log/pharos-clamav` | 2 GiB, one CPU, 128 PIDs |
| Pharos PostgreSQL | `127.0.0.1:55432` | `/var/lib/pharos-postgresql` | 512 MiB, one CPU, 128 PIDs |

The service roots sit outside the app lifecycle and package-owned `/var/lib/pharos` tree. Docker restart policies retain services across daemon restarts. Stopping/recreating containers preserves their bind-mounted data. Do not remove service data or bootstrap custody during routine cleanup.

## Local inputs and plan

Run from `ops/`. Images must already exist locally; these commands do not pull images or use remote build artifacts:

```sh
mkdir -p dist/service-images
docker image save sha256:64ca916618842ba469ef38a501e6c2f42a68281c064c03749b0126c0fb085ce5 -o dist/service-images/clamav-1.5.4.tar
docker image save sha256:57c72fd2a128e416c7fcc499958864df5301e940bca0a56f58fddf30ffc07777 -o dist/service-images/postgres-16-alpine.tar
tar -C ../pharos/.local/services/clamav/database -czf dist/service-images/clamav-signatures.tar.gz .
apb pharos_services.yml -l web0
```

The exact reviewed image IDs are pinned in the role defaults. Apply checks those identities after loading missing images and never pulls. Source signatures come from the existing local ClamAV service; validate its signature age and clean/EICAR controls before staging. Only an empty remote signature store is seeded. FreshClam remains enabled for official updates and existing signature data is never overwritten by a replayed seed.

## Apply and checks

After reviewing the plan and satisfying capacity prerequisites:

```sh
apb pharos_services.yml -l web0 -e pharos_services_apply=true
```

The role validates Compose files, starts only the two dedicated projects and requires health before continuing. The canonical scanner check verifies PONG, current signatures, clean input, EICAR rejection and persistent scan/update logs. PostgreSQL receives a local authenticated readiness query. Reapplying preserves credentials and database contents and does not recreate healthy unchanged services. Missing credentials alongside existing PostgreSQL data fail closed rather than replacing the password.

Scanner configuration comes directly from the sibling Pharos checkout. The QA overlay selects the verified image ID and resource ceiling. The containers have read-only roots, dropped capabilities, no-new-privileges and bounded temporary files/logs. Neither service mounts uploaded content or the Docker socket.

## Database cutover is separate

The new PostgreSQL instance initially contains only its operator bootstrap database. Before app selection, decide whether to retain QA data or initialize a fresh app environment, preserve existing SQLite files, create non-superuser app roles and separate app databases, and validate configured connection security. Apply each app's logical migrations through the generic Pharos CLI. Apps continue to call the same database interface; the installer does not convert databases. Do not reuse Keycloak credentials or its database for Pharos apps.

Only a separately approved cutover may change the active runtime/app database settings. Verify health, readiness and authenticated app behavior afterward; container health alone does not certify application parity.
