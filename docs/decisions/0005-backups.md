# 0005: restic for service data, Hyper Backup for the NAS, restore tests in the schedule

**Status:** accepted

## Decision
- svc-01 → DS1815+ with **restic** over SFTP: encrypted, deduplicated, scriptable, with metrics.
- DS1815+ → NAS326 and → Backblaze B2 with **Hyper Backup**, the NAS's built-in tool, with client-side encryption.
- A weekly **automated restore test**; the NAS-side copies are restore-tested by hand once a quarter.

## Why
- Databases are dumped (`pg_dump`, SQLite `.backup`) right before each snapshot. Copying the files of a running
  database gives a backup that may not open.
- A backup job that "succeeds" can still produce something that can't be restored. The restore test checks what
  matters: the files are there and the databases open.
- Both jobs publish metrics, and alerts fire on failure **and** on silence (no successful run in 36 h / 8 days),
  because a job that stopped running produces no error.

## Consequences
- The restic repository password is in the vault. Losing it makes the backups unreadable, so it's also stored
  outside the lab.
- B2 costs a little per month. Only the important shares go off-site, not the media library.
