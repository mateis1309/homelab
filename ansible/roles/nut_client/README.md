# nut_client

NUT secondary; shuts this host down cleanly when the UPS runs low.

| Variable | Default | Notes |
|---|---|---|
| `nut_ups_name` | `ups` |  |
| `nut_server` | `10.10.10.1` |  |
| `nut_remote_password` | `"{{ vault_nut_remote_password }}"` |  |

Lab-wide values (zones, hosts, firewall rules, routes) are set in `ansible/inventory/group_vars/`, not here.
