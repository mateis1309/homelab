# Add a WireGuard peer

1. On the new device (WireGuard app), create an empty tunnel. The app generates a key pair. Copy the
   **public** key.
2. Add the peer to `wireguard_peers` in `group_vars/routers.yml` with the next free address in `10.10.99.0/24`:
   ```yaml
   - name: tablet
     public_key: <public key from the app>
     ip: 10.10.99.12
   ```
3. `make router` (or `cd ansible && ansible-playbook playbooks/router.yml --tags vpn`). Existing tunnels stay up
   (`wg syncconf`). The play prints the server public key.
4. On the device, finish the tunnel:
   ```ini
   [Interface]
   Address = 10.10.99.12/32
   DNS = 10.10.99.1

   [Peer]
   PublicKey = <server public key>
   Endpoint = <public IP or DDNS name>:51820
   AllowedIPs = 10.10.0.0/16
   PersistentKeepalive = 25
   ```
   `AllowedIPs = 10.10.0.0/16` is a split tunnel (only lab traffic goes through the VPN); use `0.0.0.0/0` to send
   everything.

To revoke a device, delete its entry and run the playbook again.
