#!/usr/bin/env bash
# Task 1 — read-only hardening audit. Prints PASS / FAIL per checklist item.
# Run with: sudo bash scripts/audit.sh   (does not change anything)
FAIL=0
check() { # $1 = name, $2 = command (as string)
  if eval "$2" >/dev/null 2>&1; then echo "PASS: $1"; else echo "FAIL: $1"; FAIL=1; fi
}
echo "=== Task 1 audit — Harden the Ubuntu Host ==="
check "SSH password auth disabled" "grep -Eq '^PasswordAuthentication no' /etc/ssh/sshd_config"
check "SSH key auth enabled" "grep -Eq '^PubkeyAuthentication yes' /etc/ssh/sshd_config"
check "Root login password disabled" "grep -Eq '^PermitRootLogin (no|prohibit-password)' /etc/ssh/sshd_config"
check "UFW is active" "ufw status | grep -q 'Status: active'"
check "UFW allows SSH (22)" "ufw status | grep -q '22/tcp.*ALLOW'"
check "UFW allows HTTP (80)" "ufw status | grep -q '80/tcp.*ALLOW'"
check "UFW allows HTTPS (443)" "ufw status | grep -q '443/tcp.*ALLOW'"
check "UFW default deny incoming" "ufw status verbose | grep -q 'Default: deny (incoming)'"
check "No pending upgrades" "! apt list --upgradable 2>/dev/null | grep -q upgradable"
check "sshd config is valid" "sshd -t"
echo "=== Result ==="
if [ "$FAIL" -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "SOME CHECKS FAILED — fix the FAIL items above and re-run"; fi
exit $FAIL
