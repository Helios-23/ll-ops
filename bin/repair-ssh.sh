#!/usr/bin/env zsh

INSTANCE_NAME="pharos-llight-io"
ZONE="us-west1-a"

echo "==> Fetching current external IP..."
MY_IP=$(curl -s ifconfig.me)

if [[ -z "$MY_IP" ]]; then
  echo "[-] Failed to auto-detect IP address. Exiting."
  exit 1
fi

echo "[+] Current IP detected: ${MY_IP}"

# Read Cloud Shell public key safely
PUBKEY=$(cat ~/.ssh/id_*.pub 2>/dev/null | head -n 1)

# Generate startup script file safely without gcloud flag string parsing issues
cat << EOF > /tmp/gcp_repair_startup.sh
#!/bin/bash

# 1. Unban current IP and clear fail2ban jails
fail2ban-client unban --all
fail2ban-client unban ${MY_IP}
mkdir -p /etc/fail2ban/jail.d
echo "[DEFAULT]" > /etc/fail2ban/jail.d/custom-ignore.conf
echo "ignoreip = 127.0.0.1/8 ::1 ${MY_IP}" >> /etc/fail2ban/jail.d/custom-ignore.conf
systemctl restart fail2ban

# 2. Inject Cloud Shell public key into root, devops, and rp
for USER_HOME in /root /home/devops /home/rp; do
  if [ -d "\$USER_HOME" ]; then
    mkdir -p "\$USER_HOME/.ssh"
    chmod 700 "\$USER_HOME/.ssh"
    echo "${PUBKEY}" >> "\$USER_HOME/.ssh/authorized_keys"
    chmod 600 "\$USER_HOME/.ssh/authorized_keys"
  fi
done

# 3. Allow standard password and publickey authentication
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart ssh
EOF

echo "==> Injecting recovery metadata to ${INSTANCE_NAME}..."

# Use --metadata-from-file to bypass all string escaping bugs
gcloud compute instances add-metadata "${INSTANCE_NAME}" \
  --zone="${ZONE}" \
  --metadata-from-file=startup-script=/tmp/gcp_repair_startup.sh

if [[ $? -ne 0 ]]; then
  echo "[-] Failed to set metadata on instance."
  rm -f /tmp/gcp_repair_startup.sh
  exit 1
fi

rm -f /tmp/gcp_repair_startup.sh

echo "==> Resetting ${INSTANCE_NAME} to apply fixes..."
gcloud compute instances reset "${INSTANCE_NAME}" --zone="${ZONE}"

echo ""
echo "[+] Recovery complete! Wait ~30 seconds for boot, then test SSH access."
