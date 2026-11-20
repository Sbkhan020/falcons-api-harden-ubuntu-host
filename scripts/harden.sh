#!/usr/bin/env bash
# Task 1 — Harden the Ubuntu Host (Ubuntu 22.04)
# Run with: sudo bash scripts/harden.sh
# WARNING: test SSH key login BEFORE running this. It disables password SSH.
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root / with sudo: sudo bash scripts/harden.sh" >&2
  exit 1
fi

echo "=== 1. System updates ==="
apt update
apt upgrade -y
apt autoremove -y

echo "=== 2. SSH — key-only authentication ==="
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%F) || true
cp configs/sshd_config /etc/ssh/sshd_config
# Safety check: a key must exist for the main user before password auth goes off
if ! grep -q "ssh-" /home/*/".ssh/authorized_keys" 2>/dev/null; then
  echo "WARNING: no authorized_keys found — add your public key first, then re-run." >&2
  echo "ssh-copy-id <user>@<vm-ip>" >&2
  exit 1
fi
sshd -t
systemctl restart sshd
systemctl enable ssh

echo "=== 3. UFW — only SSH and HTTP(S) ==="
apt install -y ufw
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable
ufw status verbose

echo "=== 4. Remove / disable unnecessary services ==="
# Common non-essential services on a server VM — disable only if present.
for svc in avahi-daemon cups bluetooth ModemManager; do
  if systemctl list-unit-files | grep -q "^${svc}.service"; then
    systemctl stop "$svc" || true
    systemctl disable "$svc" || true
    systemctl mask "$svc" || true
    echo "disabled: $svc"
  fi
done

echo "=== 5. Sudo restrictions ==="
cp configs/sudoers-hardening /etc/sudoers.d/hardening
chmod 440 /etc/sudoers.d/hardening
visudo -c

echo "=== Done. Run the audit next: sudo bash scripts/audit.sh ==="
