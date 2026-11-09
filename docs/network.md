# Network

Everything on this page is generated from or must match
[`lab.yml`](../ansible/inventory/group_vars/all/lab.yml) (zones and hosts) and
[`routers.yml`](../ansible/inventory/group_vars/routers.yml) (firewall rules). If they disagree, the YAML wins.

## Zones and addressing

Each zone is one VLAN and one `/24`. The router is always `.1` and also serves DNS, DHCP and NTP on that
address. Static hosts get `.10–.99` and DHCP hands out `.100–.199`.

| Zone | VLAN | Subnet | Internet | Typical devices |
|---|---|---|---|---|
| mgmt | 10 | 10.10.10.0/24 | yes | router, switches, Proxmox host |
| servers | 20 | 10.10.20.0/24 | yes | DS1815+, svc-01, mon-01, Minecraft |
| backup | 25 | 10.10.25.0/24 | **no** | NAS326 |
| trusted | 30 | 10.10.30.0/24 | yes | laptops, phones, desktop; default for wall drops |
| iot | 40 | 10.10.40.0/24 | yes | openHAB Pi, Chromecast Audio, Echo, Ring, SpaceMonkey (being retired) |
| cameras | 50 | 10.10.50.0/24 | **no** | PoE IP cameras |
| guest | 60 | 10.10.60.0/24 | yes | visitors |
| vpn | – | 10.10.99.0/24 | yes | WireGuard peers (laptop, phone) |

Static addresses:

| Host | Address | Notes |
|---|---|---|
| router | 10.10.10.1 (+ `.1` in every zone) | |
| core-switch | 10.10.10.2 | management interface on VLAN 10 |
| poe-switch | 10.10.10.3 | management interface on VLAN 10 |
| pve | 10.10.10.20 | Proxmox UI `https://10.10.10.20:8006` |
| nas-primary | 10.10.20.10 | DSM on 5001 |
| svc-01 | 10.10.20.30 | VM 120 |
| mon-01 | 10.10.20.31 | VM 121 |
| minecraft | 10.10.20.40 | port-forwarded 25565 |
| nas-backup | 10.10.25.10 | |
| openhab | 10.10.40.10 | |

Local names resolve as `<host>.home.arpa`. Service names (`vault.`, `docs.`, `grafana.`...) under the services
domain resolve to svc-01 **inside the lab only** (dnsmasq split-horizon). The public DNS zone holds no records for
them; it is only used for Let's Encrypt DNS-01.

## Firewall policy

Default deny in both `input` and `forward`. The nftables ruleset is rendered from the zone flags and the rule list,
syntax-checked with `nft -c` before it is installed, and applied behind an automatic rollback
([ADR 0001](decisions/0001-router-as-code.md)).

Between zones (rows = source, columns = destination; "–" = dropped):

| from \ to | mgmt | servers | backup | trusted | iot | cameras | guest | internet |
|---|---|---|---|---|---|---|---|---|
| **mgmt** | | all | all | all | all | all | all | yes |
| **vpn** | all | all | all | all | all | all | all | yes |
| **servers** | metrics¹ | | rsync² | metrics¹ | metrics¹ | NVR³, metrics¹ | metrics¹ | yes |
| **trusted** | – | web 80/443 (svc-01), SMB 445 + DSM 5001 (NAS), 25565 (Minecraft) | – | | openHAB 8080/8443, cast 8008/8009/8443 | – | – | yes |
| **iot** | – | – | – | – | | – | – | yes |
| **cameras** | – | – | – | – | – | | – | **no** |
| **guest** | – | – | – | – | – | – | | yes |
| **backup** | – | – | | – | – | – | – | **no** |

¹ only from mon-01, TCP 9100 + ICMP. ² only nas-primary → nas-backup, TCP 873. ³ only svc-01 → cameras, TCP 80/554.

To the router itself: DNS, DHCP and NTP from every zone; SSH only from mgmt and vpn; NUT (3493) from mgmt and
servers; mDNS from trusted and iot; WireGuard (51820/udp) from the WAN and from trusted; node_exporter only from
mon-01.

From the internet: WireGuard, and one port forward (Minecraft, 25565/tcp → 10.10.20.40).

**Traffic inside a zone never crosses the router.** Two hosts on the servers VLAN talk through the switch, so the
router can't filter it. Those flows are filtered on the hosts: UFW on the VMs (Temper), `DOCKER-USER` on mon-01
([docker_host](../ansible/roles/docker_host)), and the DSM firewall on the DS1815+. That's also why the end-of-life
NAS326 got its own VLAN instead of sitting with the other servers.

## Switch configuration

The D-Link and Netgear are configured in their web UIs (neither has an API worth automating). Export the config
after each change and keep the export out of git.

D-Link DGS-1210-52 (T = tagged, U = untagged, PVID = VLAN for untagged frames):

| Ports | Connected to | VLANs |
|---|---|---|
| 1–3 (LACP group 1) | router `eno2–eno4` (bond0) | T: 10, 20, 25, 30, 40, 50, 60 |
| 4 | Intel NUC | U: 10 (PVID 10) · T: 20 (VMs) |
| 5 | DS1815+ LAN 1 | U: 20 |
| 6 | NAS326 | U: 25 |
| 7 | Netgear GS110TP uplink | U: 10 (switch mgmt) · T: 50 |
| 8 | MacBook (USB/Thunderbolt Ethernet) | U: 20 |
| 9 | Raspberry Pi 4 | U: 40 |
| 10 | Wi-Fi access point | U: 10 (AP mgmt) · T: 30, 40, 60 |
| 11–40 | wall drops | U: 30 |
| 41–48 | spare | disabled |
| 49–52 (SFP) | – | disabled |
| switch management IP | 10.10.10.2 | VLAN 10 |

Netgear GS110TP:

| Ports | Connected to | VLANs |
|---|---|---|
| 1–7 (PoE) | cameras | U: 50 (PVID 50) |
| 8 | uplink to D-Link port 7 | U: 10 · T: 50 |
| switch management IP | 10.10.10.3 | VLAN 10 |

## Wi-Fi

Chromecast Audio, Echo and the Ring doorbell are Wi-Fi only. They join through an access point that maps one SSID
to each of trusted, iot and guest (switch port 10, tagged 30/40/60). The guest SSID has client isolation on.

## Casting across VLANs

Phones on trusted find the Chromecast on iot through mDNS. The router runs an avahi **reflector** on VLAN 30 and 40
only, and the firewall allows trusted → iot on the cast control ports. iot can't open connections back to trusted:
replies pass as `established`, nothing else does.
