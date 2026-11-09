# Restore

All commands on svc-01 as root. Load the restic environment first:

```bash
set -a; . /etc/restic/env; set +a
restic snapshots --tag scheduled
```

## One file or folder

```bash
restic restore latest --tag scheduled --target /var/tmp/restore --include /opt/stacks/paperless/media/documents/originals/0000123.pdf
# check it, then copy it back into place
```

`restic mount /mnt/restic` (FUSE) lets you browse every snapshot as folders.

## One service (example: Paperless)

```bash
cd /opt/stacks/paperless && docker compose down
restic restore latest --tag scheduled --target / --include /opt/stacks/paperless --include /opt/backup/dumps/paperless.sql.gz
# the snapshot has no postgres/ directory (excluded on purpose): start an empty database and load the dump
docker compose up -d db && sleep 10
zcat /opt/backup/dumps/paperless.sql.gz | docker exec -i paperless-db psql -U paperless -d paperless
docker compose up -d
```

authentik works the same way (`authentik-postgresql`, dump `authentik.sql.gz`). For Vaultwarden, stop the container
and copy `/opt/backup/dumps/vaultwarden.sqlite3` over `/opt/stacks/vaultwarden/data/db.sqlite3`.

## The whole of svc-01 (VM lost)

1. `make vms`: Terraform recreates the VM (same ID, same address).
2. `make services`: hardening, Docker, stacks with **empty** data, backup timers. The role finds the existing repo
   and doesn't re-initialise it. Add the new SSH key it prints to the NAS `restic` user.
3. Stop the stacks (`docker compose down` in each `/opt/stacks/*`), then
   `restic restore latest --tag scheduled --target /`.
4. Load the database dumps as above, then start the stacks.
5. `make restore-test-now` and `make audit`.

Expected time: about 30–45 minutes, most of it Paperless media.

## The DS1815+ is gone

- The restic repository also exists on the NAS326 and B2 (Hyper Backup copies of the `restic` share).
- Restore the share from Hyper Backup to any machine (Hyper Backup Explorer runs on Windows, macOS and Linux), point
  `RESTIC_REPOSITORY` at it, and restore as above.
