# nut_server

NUT server for a USB UPS; tells the hypervisor and NAS when to shut down.

| Variable | Default | Notes |
|---|---|---|
| `nut_ups_name` | `ups` |  |
| `nut_ups_driver` | `usbhid-ups` |  |
| `nut_ups_description` | `UPS` |  |
| `nut_listen` | `[127.0.0.1]` |  |
| `nut_port` | `3493` |  |
| `nut_admin_password` | `"{{ vault_nut_admin_password }}"` | Passwords come from the vault (see ansible/vault.example.yml). |
| `nut_local_password` | `"{{ vault_nut_local_password }}"` |  |
| `nut_remote_password` | `"{{ vault_nut_remote_password }}"` |  |

Lab-wide values (zones, hosts, firewall rules, routes) are set in `ansible/inventory/group_vars/`, not here.
