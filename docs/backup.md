# Backups

## Layout (3-2-1)

Three copies of everything that matters, on two different devices, one of them off-site.

```text
svc-01 (service data)                          DS1815+ (media library, personal files)
   │ restic, nightly 03:15, encrypted              │
   ▼                                               │
DS1815+  /restic/svc-01  ◄──────────────────────────┘   copy 1
   │
   ├── Hyper Backup, nightly ──► NAS326 (VLAN 25, rsync)       copy 2: second device
   └── Hyper Backup, weekly ───► Backblaze B2, client-side      copy 3: off-site
                                 encryption
```

| What | Where | Tool | Schedule | Retention |
|---|---|---|---|---|
| svc-01: compose files, app data, DB dumps | DS1815+ `/restic/svc-01` | restic over SFTP | daily 03:15 (±15 min) | 7 daily, 4 weekly, 6 monthly |
| DS1815+ shares incl. the restic repo | NAS326 | Hyper Backup (rsync) | daily 05:30 | 14 versions |
| DS1815+ important shares incl. the restic repo | Backblaze B2 | Hyper Backup, client-side encryption | weekly | 8 versions |
| Router, Proxmox host, VMs | this git repository | Ansible + Terraform | every change | git history |

**Not backed up:** camera footage (kept 7 days by design), Prometheus metrics (30 days, rebuildable), the bulk media
library on B2 (too large to send off-site; it has two local copies). The router and VMs are rebuilt from this repo,
not restored. Their only state is secrets, and those live in the Ansible vault. Keep a copy of the vault and its password outside the lab (password manager + USB stick).

## What restic backs up on svc-01

- `/opt/stacks`: every compose stack, its config and bind-mounted data (Vaultwarden, Paperless media, authentik
  media...)
- `/opt/backup/dumps`: **consistent** database dumps taken just before the snapshot: `pg_dump` for authentik and
  Paperless, SQLite `.backup` for Vaultwarden
- Excluded: live PostgreSQL and Valkey data directories (copying the files of a running database doesn't give a
  usable backup; the dumps replace them) and Frigate recordings

Defined in [`services.yml`](../ansible/inventory/group_vars/services.yml) (`restic_*`), implemented in
[`restic_backup`](../ansible/roles/restic_backup).

## Restore testing

A backup counts only if it restores. Every Sunday at 05:00, `homelab-restore-test`:

1. restores the database dumps and the key paths from the latest snapshot into a scratch directory,
2. checks that the expected files exist (`restic_restore_test_paths`),
3. checks that each PostgreSQL dump is complete (gzip intact, ends with the pg_dump completion marker) and that the
   SQLite copy passes `PRAGMA integrity_check`,
4. runs `restic check --read-data-subset=5%`, re-reading a random 5% of the repository data each week.

Both jobs write Prometheus metrics through node_exporter's textfile collector:

| Metric | Alert |
|---|---|
| `homelab_backup_last_exit_code` | `BackupFailed` if ≠ 0 |
| `homelab_backup_last_success_timestamp_seconds` | `BackupTooOld` after 36 h |
| `homelab_restore_test_last_success_timestamp_seconds` | `RestoreTestTooOld` after 8 days |
| `homelab_backup_duration_seconds` | dashboard only |

A failed run keeps the previous "last success" value, so the age alerts stay accurate.

CI runs this same pipeline against a throwaway repository on every push
([`backup_e2e.yml`](../ansible/tests/backup_e2e.yml)): back up sample data, pass the restore test, delete a file the
test expects, back up again, and check that the restore test now **fails**, reports exit code 1 and keeps the old
success timestamp.

The NAS-side copies (Hyper Backup) are checked by hand once a quarter. Use Hyper Backup Explorer to restore one
folder and one file from each destination to a scratch share and compare them with the originals.

## NAS setup (DSM and NAS326 web UIs)

DS1815+, as the restic target:
1. Create shared folder `restic` (no recycle bin, no snapshots needed: restic is already versioned).
2. Create user `restic`: read/write on `restic` only, no other shares, no DSM/application access except SFTP.
3. Control Panel → File Services → FTP → enable **SFTP** (port 22).
4. Add the public key that the `restic_backup` role prints on its first run to `restic`'s
   `~/.ssh/authorized_keys` (enable user home service first).
5. DSM firewall: allow 22/tcp from `10.10.20.30` only; 5001 from mgmt, trusted and vpn.
6. Run `make services` again; the role initialises the repository.

NAS326, as the second copy:
1. Static IP `10.10.25.10`, gateway `10.10.25.1`. It has no internet by design, so update its firmware by hand
   when Zyxel publishes a fix.
2. Enable the rsync server only; disable everything else (Twonky, cloud apps, UPnP).
3. DS1815+ Hyper Backup → *rsync-compatible server* → `10.10.25.10`, encrypted backup on.

Off-site:
1. Backblaze B2 bucket (private, object lock off), application key restricted to that bucket.
2. DS1815+ Hyper Backup → *Backblaze B2*, **client-side encryption on**. Keep the encryption key in the password
   manager **and** on paper: without it the off-site copy is useless.

## Restoring

Step by step for one file, one service, or the whole of svc-01: [runbooks/restore.md](runbooks/restore.md).
