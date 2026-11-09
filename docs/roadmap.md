# Roadmap

Roughly in order.

- [ ] **Roll out** steps 1–8 from the README status table.
- [ ] **Wi-Fi AP with VLAN SSIDs** (trusted / iot / guest): required before the iot and guest zones are useful.
- [ ] **Re-terminate the Cat5e phone runs** to RJ45 for the PoE cameras, then enable Frigate.
- [ ] **openHAB as code**: manage the Pi with Ansible (Raspberry Pi OS Lite), and keep openHAB's config in git.
- [ ] **Retire SpaceMonkey** once the security-system integration runs on openHAB.
- [ ] **SNMP exporter** for the D-Link and Netgear: port errors and traffic per VLAN in Grafana.
- [ ] **NUT exporter**: UPS battery and load in Grafana, alert when on battery.
- [ ] **Wazuh** (or CrowdSec) for log collection and intrusion detection; needs more RAM on the NUC.
- [ ] **Suricata on the router** in IDS mode for the WAN; check the C3558 can keep up at 1 Gbit.
- [ ] **DS1815+**: bond two of its four ports (LACP), and plan its replacement (see [hardware.md](hardware.md)).
- [ ] **Local LLM** (Ollama) on the NUC, if it has enough RAM, for documents that must stay in the house.
- [ ] **Molecule tests** for the router roles in a container with nftables (as Temper does for its roles).
