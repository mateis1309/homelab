# 0001: Router as code on Ubuntu, not OPNsense/pfSense

**Status:** accepted

## Context
The Supermicro already runs Ubuntu Server (DHCP, NAT, OpenVPN), configured by hand. The options were to keep Ubuntu
and manage it with Ansible, or to move to OPNsense or pfSense.

## Decision
Keep Ubuntu, and generate the whole router configuration (netplan, nftables, dnsmasq, chrony, avahi, WireGuard,
NUT) from `lab.yml` with Ansible.

## Why
- **Reviewable.** Every rule is a line in a YAML file and a diff in a pull request. OPNsense stores its state in
  an XML file edited through a web UI; it can be automated, but nobody reads those diffs.
- **One model.** The firewall, DHCP scopes, DNS records and Terraform VMs all come from the same zone and host list,
  so they can't drift apart.
- **Testable.** CI renders the ruleset and runs `nft -c`, `dnsmasq --test` and `netplan generate` on it.
- Same Ansible/Temper tooling as every other host.

## Consequences
- No web UI for the firewall: changes go through git. For a small office I'd still recommend OPNsense, because
  non-technical staff can look after it. This repo optimises for the opposite.
- A bad network change can cut off SSH. That's handled by `safe_apply`: a systemd timer rolls the change back
  after 120 s unless Ansible opens a **new** SSH connection afterwards and disarms it. The very first cut-over
  (flat LAN → VLANs) changes the router's address, so it's done once from the console
  ([bootstrap](../runbooks/bootstrap.md)).
- The ruleset owns only `table inet homelab`. It replaces that table atomically instead of `flush ruleset`, so
  fail2ban's tables survive reloads.
