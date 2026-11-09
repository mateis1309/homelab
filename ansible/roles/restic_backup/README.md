# restic_backup

Nightly restic backups with consistent DB dumps, weekly automated restore test, Prometheus metrics.

| Variable | Default | Notes |
|---|---|---|
| `restic_repository` | `""` |  |
| `restic_password` | `"{{ vault_restic_password }}"` |  |
| `restic_backup_paths` | `[]` |  |
| `restic_excludes` | `[]` |  |
| `restic_db_dumps` | `[]` |  |
| `restic_dump_dir` | `/opt/backup/dumps` |  |
| `restic_ssh_key` | `/root/.ssh/restic_ed25519` |  |
| `restic_keep_daily` | `7` |  |
| `restic_keep_weekly` | `4` |  |
| `restic_keep_monthly` | `6` |  |
| `restic_backup_schedule` | `"*-*-* 03:15:00"` |  |
| `restic_restore_test_schedule` | `"Sun *-*-* 05:00:00"` |  |
| `restic_restore_test_paths` | `[]` |  |
| `restic_check_read_subset` | `5%` | Share of pack files whose contents are re-read and verified on each restore test. |
| `restic_metrics_dir` | `/var/lib/prometheus/node-exporter` |  |
| `restic_config_dir` | `/etc/restic` |  |
| `restic_cache_dir` | `/var/cache/restic` |  |
| `restic_lib_dir` | `/usr/local/lib/homelab` |  |
| `restic_scratch_dir` | `/var/tmp` |  |

Lab-wide values (zones, hosts, firewall rules, routes) are set in `ansible/inventory/group_vars/`, not here.
