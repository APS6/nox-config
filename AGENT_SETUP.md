# Agent-Driven Setup & Recovery Protocol

**DO NOT RUN THIS AS A BASH SCRIPT.** This document is intended to be read by an AI Agent (like Antigravity or Opencode) to completely reconstruct `aps6`'s system and server from a bare-metal state.

If the laptop or server has died and you are performing a disaster recovery, read this document carefully and execute the steps interactively.

## Prerequisites (User Action Required)
Before an agent can reconstruct the setup, the user must provide:
1. A fresh installation of CachyOS (Laptop) or Fedora Workstation (Server).
2. The agent running with read access to this repository (`nox-config`) and `agent-skills`.
3. The user's Bitwarden credentials (which contain the laptop's `secret.key` for env decryption and the server's `backup.env` for Cloudflare R2 access).

---

## 💻 1. Laptop Reconstruction (CachyOS)

### A. Dependencies & Packages
1. Read `packages.txt` in this repository.
2. The file contains a list of explicit `pacman` packages and `flatpak` apps.
3. Use the system package manager to reinstall all missing packages from these lists. 
   - Note: Ignore AUR/Pacman conflicts, just install the bulk of the required desktop environment (Niri, Noctalia, Ghostty, etc.).

### B. Dotfiles Integration
1. This entire repository (`nox-config`) acts as the user's dotfiles. 
2. Ensure the repository is placed at `~/.config`.
3. Link or configure standard locations (e.g., ensure `~/.local/bin` maps correctly if needed, though most binaries are already in `~/.config/bin`).

### C. System Configuration (PAM & Auth)
1. Read the `system-config` skill in the `agent-skills` repository.
2. Follow the exact instructions under **"Authentication & PAM"** to re-enroll fingerprints (`fprintd-enroll`).
3. Manually recreate the PAM configurations for `/etc/pam.d/noctalia-lock` and `/etc/pam.d/login` exactly as described in the skill.
4. Set up the `NOCTALIA_PAM_SERVICE` systemd override exactly as documented.

### D. Zero-Trust Env Decryption
1. Retrieve `secret.key` from the user's Bitwarden vault.
2. Place it precisely at `~/.config/laptop-backup/secret.key` and set permissions to `600`.
3. Read the "Zero-Trust Laptop .env Backup" section of the `system-config` skill.
4. Enable the `backup-envs.timer` systemd user service.
5. If you need to restore current `.env` files from the server, run `restore_envs`.

---

## 🖥️ 2. Server Reconstruction (Domenico - Fedora)

### A. Baseline Host Configuration
1. **Network Quirks**: Read the "CRITICAL QUIRKS" section in the `domenico-infrastructure` skill. 
   - You MUST disable IPv6 on the outgoing interface via `sysctl` (`net.ipv6.conf.<interface>.disable_ipv6 = 1`) to fix Docker MTU blackholes.
2. **SELinux**: Ensure SELinux remains enforcing. All Docker bind mounts must use `:z` or `:Z`.
3. **Firewall**: `firewalld` and `UFW` are currently **inactive**. Do not enforce UFW rules unless instructed otherwise, as it relies on Tailscale and Docker's iptables for routing.

### B. Users & Permissions
1. Recreate the `sftpuser` (UID 1001) and `sftpuser-private` (UID 1002) exactly.
2. Ensure they are chrooted to `/srv/sftp` and `/srv/sftp-private` via `sshd_config`.

### C. Dependencies & Services
1. Read `domenico_packages.txt` for a historical list of installed RPMs. Reinstall Docker, Tailscale, and Cloudflared.
2. Read `domenico_timers.txt`. Manually recreate and enable the systemd user timers for `aps6`:
   - `backup.timer`
   - `music-sync.timer`
   - `agy-battery-monitor.timer`

### D. Cloudflare R2 Disaster Recovery (Crown Jewels)
1. Retrieve `backup.env` (R2 credentials) from the user's Bitwarden vault.
2. Place it at `/home/aps6/backup/backup.env` (permissions `600`).
3. Follow the **"Disaster Recovery Operations"** section in the `domenico-infrastructure` skill to run `restic restore`.
4. Restore the PostgreSQL dumps into the new database containers.

### E. Kamal Re-linking
1. Once Kamal proxy is running (ensuring port 443 is free for Tailscale), run `kamal deploy` from the laptop for `study` and `adknockout` to rebuild the web containers.
