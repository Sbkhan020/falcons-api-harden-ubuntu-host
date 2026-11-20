# Task 1 — Harden the Ubuntu Host

**Ezitech Internship — Cyber Security, SOC Analyst (Blue Team)**
**Intern:** Muhammad Sumyan Safdar (ETI-40371)
**Project:** Falcons Sports Club API Security Monitoring & Incident Response
**Task:** Harden the Ubuntu Host — due 20 Nov 2026
**Host:** Ubuntu 22.04 VM in the intern's own home lab (2 GB RAM, 2 CPUs, browser closed while the VM runs, on the supervisor's advice for a slow laptop)

## What this does

Secures the Ubuntu VM that will host the API and log collector, so only SSH and HTTP(S) are reachable, only key-based SSH login works, unnecessary services are stopped, and the system is fully updated.

Checklist the mentor reviews against — all covered here:

- [x] SSH key-only authentication is enforced
- [x] UFW allows only SSH and HTTP(S) traffic (22, 80, 443)
- [x] No unnecessary services are running
- [x] System is fully updated and no pending upgrades

## Files

| File | Purpose |
|---|---|
| `scripts/harden.sh` | Main hardening run: updates, SSH, UFW, services, sudo |
| `configs/sshd_config` | Hardened SSH server config (password auth off, keys only) |
| `scripts/ufw-rules.sh` | UFW rules only — allow 22, 80, 443, deny everything else |
| `scripts/audit.sh` | Read-only verification — prints PASS / FAIL per checklist item |
| `configs/sudoers-hardening` | Sudo restrictions (no password-less sudo for normal users, timestamp timeout) |

## How to run — on the Ubuntu 22.04 VM

```bash
# 1. Copy your SSH public key to the VM first, and test key login works.
#    Do NOT disable password SSH until key login is confirmed.
ssh-copy-id sumyan@<vm-ip>
ssh -i ~/.ssh/id_ed25519 sumyan@<vm-ip>   # must log in without a password prompt

# 2. Run the hardening script (needs sudo)
sudo bash scripts/harden.sh

# 3. Verify — must show all PASS
sudo bash scripts/audit.sh
```

Reboot after the first run, then log in again with the key only to confirm password login is rejected:

```bash
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no sumyan@<vm-ip>
# expected: Permission denied (publickey)
```

## What was hard

The laptop is slow, so the VM was given only 2 GB RAM and 2 CPUs and the browser was closed while it ran — giving it more RAM made the host worse, not better. The other hard part was ordering: SSH keys had to be tested *before* password authentication was switched off, otherwise the VM could have been locked out.

## What was left out

No live URL — this is a host-hardening task, the VM is a local home-lab host and is not exposed online. No extra services were installed; the API and log collector come in Task 2.

## Verification (audit.sh)

`audit.sh` checks, without changing anything:

1. `PasswordAuthentication no` and `PubkeyAuthentication yes` in sshd config
2. `ufw status` — only 22/tcp, 80/tcp, 443/tcp allowed
3. `ss -tlnp` — only SSH and HTTP(S) listeners
4. `apt list --upgradable` — no pending upgrades
5. No password-less sudo for normal users

Run it after every change. If any check prints FAIL, fix that step and re-run.
