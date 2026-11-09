# 0003: Proxmox VE on the NUC, VMs created by Terraform

**Status:** accepted

## Decision
The NUC runs Proxmox VE 9. VMs are declared in `lab.yml` (a `vm:` block on a host) and created by Terraform with the
`bpg/proxmox` provider, cloned from a cloud-init template that the `pve_host` role builds.

## Why
- VMs give strong isolation between the service host and the monitoring host, with snapshots before risky upgrades.
- Terraform reads `lab.yml` directly (`yamldecode`), so a VM's VLAN, address and size are defined once and shared
  with Ansible's inventory, DNS and firewall.
- Temper (my hardening project) targets libvirt. Its Ansible side is reused here unchanged through a git submodule;
  the Terraform side is the Proxmox equivalent of Temper's libvirt modules.

## Details
- Terraform authenticates with an API token for `terraform@pve`, whose role holds only the privileges the provider
  needs. No root password, no SSH.
- `qemu-guest-agent` is baked into the template with `virt-customize`, so Terraform can read the VM state on first
  boot instead of timing out.
- The host uses a VLAN-aware bridge: VLAN 10 untagged for itself, VMs tagged per zone.

## Consequences
- The NUC is a single point of failure for the services. Acceptable: everything on it can be rebuilt from git plus
  the restic backup ([restore runbook](../runbooks/restore.md)).
