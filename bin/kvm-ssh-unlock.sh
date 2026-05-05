#!/usr/bin/env bash
set -euo pipefail

# KVM console recovery script for SSH lockout caused by hardening rules.
# Run as root on the server console.
#
# Optional: pass allowed users as first argument (space-separated string).
# Example:
#   bash kvm-ssh-unlock.sh "devops j"

ALLOWED_USERS="${1:-devops j}"
SSHD_CONFIG="/etc/ssh/sshd_config"
PAM_SSHD="/etc/pam.d/sshd"
ALLOWED_USERS_FILE="/etc/ssh/allowed_users"

timestamp="$(date +%Y%m%d-%H%M%S)"

echo "[1/6] Backing up SSH and PAM config..."
cp -a "$SSHD_CONFIG" "${SSHD_CONFIG}.bak-${timestamp}"
cp -a "$PAM_SSHD" "${PAM_SSHD}.bak-${timestamp}"

echo "[2/6] Removing global lockout (DenyUsers *) if present..."
sed -i '/^[[:space:]]*DenyUsers[[:space:]]\+\*[[:space:]]*$/d' "$SSHD_CONFIG"

echo "[3/6] Ensuring AllowUsers is set..."
if grep -Eq '^[[:space:]]*AllowUsers[[:space:]]+' "$SSHD_CONFIG"; then
  sed -i -E "s|^[[:space:]]*AllowUsers[[:space:]]+.*$|AllowUsers ${ALLOWED_USERS}|" "$SSHD_CONFIG"
else
  printf '\nAllowUsers %s\n' "$ALLOWED_USERS" >> "$SSHD_CONFIG"
fi

echo "[4/6] Writing /etc/ssh/allowed_users and fixing PAM check..."
printf '%s\n' $ALLOWED_USERS > "$ALLOWED_USERS_FILE"
chmod 0600 "$ALLOWED_USERS_FILE"
chown root:root "$ALLOWED_USERS_FILE"

if grep -Eq 'pam_listfile\.so.*file=/etc/ssh/allowed_users' "$PAM_SSHD"; then
  sed -i -E \
    's|^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_listfile\.so.*file=/etc/ssh/allowed_users.*$|account required pam_listfile.so item=user sense=allow file=/etc/ssh/allowed_users onerr=fail|' \
    "$PAM_SSHD"
else
  printf '\n# KVM recovery: only allow specific SSH users\naccount required pam_listfile.so item=user sense=allow file=/etc/ssh/allowed_users onerr=fail\n' >> "$PAM_SSHD"
fi

echo "[5/6] Validating sshd config..."
sshd -t

echo "[6/6] Restarting SSH service..."
if systemctl list-unit-files | grep -q '^ssh\.service'; then
  systemctl restart ssh
else
  systemctl restart sshd
fi

echo "Done. Current effective AllowUsers line:"
grep -E '^[[:space:]]*AllowUsers[[:space:]]+' "$SSHD_CONFIG" || true
