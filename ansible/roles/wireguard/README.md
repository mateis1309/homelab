# wireguard

WireGuard remote access; the server private key never leaves the router.

| Variable | Default | Notes |
|---|---|---|
| `wireguard_interface` | `wg0` |  |
| `wireguard_address` | `10.10.99.1/24` |  |
| `wireguard_port` | `51820` |  |
| `wireguard_peers` | `[]` |  |
| `wireguard_disable_openvpn` | `false` |  |
| `wireguard_openvpn_units` | `[openvpn-server@server, openvpn@server, openvpn]` |  |

Lab-wide values (zones, hosts, firewall rules, routes) are set in `ansible/inventory/group_vars/`, not here.
