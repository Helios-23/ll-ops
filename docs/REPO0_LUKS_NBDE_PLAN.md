# repo0 LUKS/NBDE plan

## Problem statement

`repo0` is a live Ubuntu 22 server with FIPS enabled. The goal is to add data-at-rest protection for the root disk while still allowing unattended reboots.

That combination is only defensible if the unlock material is not stored on the same disk. Storing a local keyfile on the unencrypted boot path would satisfy convenience, but it would not materially protect data at rest against disk theft.

## Recommendation

Use `LUKS2` for disk encryption and `Clevis` for unattended boot unlock, backed by a `Tang` server or an `sss` policy over multiple Tang servers. Keep a separate recovery passphrase in a PBKDF2 key slot for console recovery and FIPS compatibility.

This repo now contains `ops/roles/luks_nbde_client` and `ops/repo0_nbde.yml` for the client-side Clevis binding step. They are intentionally scoped to hosts that are already installed on LUKS.

## Important constraint on the current repo0 host

Do not treat in-place encryption of the currently running root filesystem as the default path.

Reasons:

1. `repo0` is remote and headless.
2. Root-disk conversion is invasive and failure recovery depends on console or rescue access.
3. Ubuntu FIPS adds a second constraint: at least one LUKS key slot must use PBKDF2 before the system can rely on FIPS mode.

For `repo0`, the safer plan is a rebuild or rescue-mode migration, not a casual in-place conversion during normal service hours.

## Recommended rollout for repo0

1. Preflight
   - Confirm Hetzner rescue/KVM access works before touching storage.
   - Capture application backups and a host-level snapshot.
   - Record current block layout with `lsblk -f`, `blkid`, `findmnt /`, and `pvs/vgs/lvs` if LVM is in use.
   - Decide whether the boot path will use DHCP in initramfs. Tang-based unlock depends on early network availability.

2. Separate trust domain for unattended unlock
   - Stand up at least one Tang server that is not `repo0`.
   - Prefer two Tang servers with Clevis `sss` for availability.
   - Do not colocate Tang on the same disk or same host you are trying to protect.

3. Reinstall or offline-migrate onto LUKS2
   - Preferred: provision a replacement `repo0` instance with Ubuntu 22 installed on LUKS2 from day one.
   - Alternative: boot the existing server into rescue mode and perform an offline migration with explicit rollback.
   - Avoid online root-disk conversion unless you are prepared for extended console-led recovery.

4. Preserve FIPS compatibility
   - Before enabling or re-enabling the steady-state FIPS boot path, ensure at least one LUKS key slot uses PBKDF2.
   - Keep a manual recovery passphrase even after Clevis is bound.

5. Bind unattended unlock
   - Run `ops/repo0_nbde.yml` with a vaulted `luks_nbde_luks_device`, existing LUKS secret, and Clevis pin config.
   - Rebuild initramfs and test at least one console-observed reboot before cutover.

6. Migrate repo0 services
   - Restore or rsync Forgejo data.
   - Reapply `ops/setup_epytype.yml` role set as needed.
   - Validate Forgejo HTTP, SSH on 2222, mail, and backups.

7. Cut over
   - Move DNS or IP attachment only after the encrypted host survives repeated unattended reboots.

## Suggested Clevis policy for repo0

Single Tang server:

```json
{"url":"http://<tang-host>:9090"}
```

Two Tang servers with one required for availability:

```json
{"t":1,"pins":{"tang":[{"url":"http://tang-a:9090"},{"url":"http://tang-b:9090"}]}}
```

Two Tang servers with both required for stronger separation:

```json
{"t":2,"pins":{"tang":[{"url":"http://tang-a:9090"},{"url":"http://tang-b:9090"}]}}
```

The `t=1` policy is usually the better operational fit for a single reboot-critical repo host. `t=2` is stricter, but one Tang outage prevents unattended boot.

## Example variables for `ops/repo0_nbde.yml`

Store secrets in Ansible Vault rather than plaintext group vars.

```yaml
luks_nbde_luks_device: /dev/disk/by-uuid/<luks-uuid>
luks_nbde_clevis_pin: tang
luks_nbde_clevis_config:
  url: "http://10.0.0.10:9090"
luks_nbde_require_fips_compatible_pbkdf2: true
luks_nbde_manage_recovery_pbkdf2_slot: true
luks_nbde_existing_unlock_secret: "{{ vault_all.repo0_luks.current_passphrase }}"
luks_nbde_recovery_passphrase: "{{ vault_all.repo0_luks.recovery_passphrase }}"
```

## Operational notes

- Tang gives unattended unlock only when the machine can reach Tang during early boot.
- If early boot networking is not reliable on your exact install path, the fallback is manual console unlock or a different trust anchor such as TPM.
- Clevis binding does not rotate the LUKS master key. Do not clone pre-encrypted cloud images between instances.
