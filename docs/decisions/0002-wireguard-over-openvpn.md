# 0002: WireGuard replaces OpenVPN

**Status:** accepted

## Decision
Remote access moves from OpenVPN to WireGuard. Peers get a /32 in `10.10.99.0/24` and the same reach as mgmt.

## Why
- Far less configuration and no PKI to maintain (a key pair per peer instead of a CA, certificates and a CRL).
- Fast on the Atom C3558 and on phones; reconnects instantly when the phone changes networks.
- Silent to scans: no reply to unauthenticated packets.
- The server's private key is generated on the router and loaded at start-up with `wg set ... private-key`, so it
  never passes through Ansible, the logs or git.

## Consequences
- WireGuard has no user accounts. Revoking a device means removing its peer and re-running the playbook.
- Admin access from home also goes through WireGuard (51820/udp is open from trusted), so the laptop can stay on
  the trusted VLAN.
- OpenVPN stays up until every peer has moved (`wireguard_disable_openvpn`).
