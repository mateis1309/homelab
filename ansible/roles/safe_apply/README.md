# safe_apply

Apply a risky network change with an automatic rollback (dead man's switch).

| Variable | Default | Notes |
|---|---|---|
| `safe_apply_unit` | `homelab-rollback` | Name of the transient systemd unit that holds the rollback (one per kind of change). |
| `safe_apply_rollback_cmd` | `""` | Absolute path of a script that restores the previous state. Must work with no network. |
| `safe_apply_commit_cmd` | `""` | Command that applies the new state. Runs detached so a dropped SSH session cannot kill it. |
| `safe_apply_timeout` | `120` |  |

Lab-wide values (zones, hosts, firewall rules, routes) are set in `ansible/inventory/group_vars/`, not here.
