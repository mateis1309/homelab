# stacks

Render and run Docker Compose stacks from templates/<stack>/.

| Variable | Default | Notes |
|---|---|---|
| `stacks_root` | `/opt/stacks` |  |
| `stacks_enabled` | `[]` |  |
| `stacks_data_dirs` | `(list/map, see defaults)` | Bind-mounted data directories (created before first start, with the owner the image runs as). |
| `traefik_routes` | `[]` |  |
| `traefik_acme_email` | `""` |  |
| `paperless_ocr_language` | `eng` |  |
| `frigate_record_retain_days` | `7` |  |
| `frigate_cameras` | `[]` |  |
| `monitoring_node_targets` | `[]` |  |
| `monitoring_backup_hosts` | `[]` |  |
| `monitoring_backup_max_age_hours` | `36` |  |
| `monitoring_restore_test_max_age_days` | `8` |  |

Lab-wide values (zones, hosts, firewall rules, routes) are set in `ansible/inventory/group_vars/`, not here.
