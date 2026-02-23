#!/bin/bash
set -euo pipefail

DEV_USER="dev1"
DEV_PUBKEY="${bootstrap_public_key}"

id -u "$DEV_USER" >/dev/null 2>&1 || useradd -m "$DEV_USER"
mkdir -p "/home/$DEV_USER/.ssh"
echo "$DEV_PUBKEY" > "/home/$DEV_USER/.ssh/authorized_keys"
chown -R "$DEV_USER:$DEV_USER" "/home/$DEV_USER/.ssh"
chmod 700 "/home/$DEV_USER/.ssh"
chmod 600 "/home/$DEV_USER/.ssh/authorized_keys"

groupadd -f wheel
usermod -aG wheel "$DEV_USER"

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd || systemctl restart ssh

dnf -y install python3 git jq