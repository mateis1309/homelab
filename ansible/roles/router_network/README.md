# router_network

WAN + LACP bond + one VLAN interface per zone, via netplan.

| Variable | Default | Notes |
|---|---|---|
| `router_network_file` | `/etc/netplan/60-homelab.yaml` |  |
| `router_network_staged` | `/etc/netplan/60-homelab.yaml.staged` |  |
| `router_network_backup` | `/var/backups/homelab-netplan-previous.tar` |  |
| `router_network_wan_dhcp` | `true` |  |
| `router_network_live_apply` | `false` |  |
| `router_rollback_seconds` | `120` |  |

Lab-wide values (zones, hosts, firewall rules, routes) are set in `ansible/inventory/group_vars/`, not here.
