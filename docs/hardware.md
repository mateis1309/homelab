# Hardware

Mostly second-hand. Each device has the job that fits it, and the known weaknesses of old gear are handled
in the design rather than ignored.

| Device | Specs | Role | Managed by |
|---|---|---|---|
| Supermicro SYS-A2SDI-4C4L-FIO | Atom C3558 (4 cores, AES-NI), 4× 1GbE | Router/firewall | Ansible (`routers`) |
| D-Link DGS-1210-52 | 48× 1GbE + 4 SFP, 802.1Q, LACP | Core switch | Web UI, [network.md](network.md) |
| Netgear GS110TP | 8× PoE 1GbE + 2 SFP | Camera PoE | Web UI, [network.md](network.md) |
| Intel NUC | | Proxmox VE 9 hypervisor | Ansible (`hypervisors`) + Terraform |
| Synology DS1815+ | 8-bay, 32 TB, Atom C2538, 4× 1GbE | Primary storage, restic target | DSM, [backup.md](backup.md) |
| Zyxel NAS326 | 2-bay | Second copy of the NAS data | Web UI, [backup.md](backup.md) |
| Raspberry Pi 4 | ARM | openHAB | – (roadmap) |
| MacBook Pro | screen broken, runs closed | Minecraft server | – |
| SpaceMonkey | backup appliance | Legacy security-system integration, being retired | – |
| CyberPower UPS | USB | Powers the rack; NUT on the router | Ansible (`nut_server`) |
| Vanguard DA8050 + 150 W amp, mixer, Chromecast Audio, Echo | | Whole-home audio, Ring chime | – (iot VLAN) |

## Known risks and what's done about them

### Synology DS1815+: Atom C2000 clock defect

The DS1815+ uses an Intel Atom C2538. That chip family has a documented erratum (AVR54): after years of use, the
LPC clock can stop and the unit no longer boots. Synology gave affected models an extended warranty in 2017 and
says units built from February 2017 onward include Intel's board-level fix. Community reports put that at serial
numbers starting with `172` or later.

Mitigation:
- Check the serial number.
- Treat the NAS as a box that can die **without warning**. Nothing exists only on it: restic data has two more
  copies (NAS326, B2), and the service configs are in git.
- Synology volumes (SHR/RAID) can be moved to another Synology or read with mdadm/LVM on Linux, so a dead
  chassis doesn't mean lost data. Write down the volume layout and disk order.

### Zyxel NAS326: end of life

Zyxel ended vulnerability support for the NAS326 on 31 Dec 2023. In June 2024 it still released an emergency
firmware, **V5.21(AAZF.17)C0**, for three critical unauthenticated command-injection/RCE bugs (CVE-2024-29972,
-29973, -29974). Two lower-severity privilege bugs (CVE-2024-29975, -29976) were left unpatched. CVE-2024-29973 was
later seen exploited by a Mirai-like botnet.

Mitigation:
- Firmware on AAZF.17 or later (check the version in the web UI before connecting it).
- **Own VLAN (25), no internet in either direction.** Only the DS1815+ can reach it (rsync, TCP 873) and only
  mgmt can reach its web UI. A compromised device elsewhere in the house can't even see it.
- It only ever *receives* encrypted Hyper Backup data, so its disks hold no readable copy.
- All apps and services except rsync are disabled. Replace it when a cheap supported box turns up.

### MacBook Pro running closed 24/7

Lithium batteries kept at 100% and warm for months can swell. Check the battery health in System Information
every few months, keep it on a hard surface with airflow, and cap the charge (macOS Optimised Battery Charging, or
a charge limiter). Replace the battery or the machine if the case starts to bulge.

### Single NIC on the NUC

Management (VLAN 10, untagged) and VM traffic (VLAN 20, tagged) share one port. That's fine at this scale, but
a mistake in the switch port config takes down both. That's why `pve_manage_network` is off by default and the
port's VLAN settings are written down in [network.md](network.md).

### One router

The router is a single point of failure for the whole house. It's rebuilt from this repository (Ubuntu install +
`make router`). Keep a spare consumer router with a known config in a drawer; it can bridge the house to the modem
while the Supermicro is rebuilt.
