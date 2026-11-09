# pve_host

Proxmox VE post-install - repos, VLAN-aware bridge, Terraform API user, cloud-init template.

| Variable | Default | Notes |
|---|---|---|
| `pve_manage_repos` | `true` | Repositories: use the free no-subscription repo instead of the enterprise one. |
| `pve_manage_network` | `false` | /etc/network/interfaces: VLAN-aware bridge on the single NIC. Off by default because a mistake here takes the host offline; enable after checking pve_nic. |
| `pve_nic` | `enp86s0` |  |
| `pve_bridge` | `vmbr0` |  |
| `pve_mgmt_vlan` | `10` |  |
| `pve_terraform_user` | `terraform@pve` | Terraform API access (least privilege role, token without privilege separation) |
| `pve_terraform_role` | `TerraformProv` |  |
| `pve_terraform_token` | `tf` |  |
| `pve_terraform_privileges` | `(list/map, see defaults)` |  |
| `pve_template_id` | `9000` | Cloud-init template that Terraform clones |
| `pve_template_name` | `ubuntu-2404-cloud` |  |
| `pve_template_storage` | `local-lvm` |  |
| `pve_template_image_url` | `https://cloud-images.ubuntu.com/noble/current/noble-serve...` |  |
| `pve_template_image_path` | `/var/lib/vz/template/iso/noble-server-cloudimg-amd64.img` |  |
| `pve_template_bake_agent` | `true` | Bake qemu-guest-agent into the image so Terraform can read the VM state on first boot. |

Lab-wide values (zones, hosts, firewall rules, routes) are set in `ansible/inventory/group_vars/`, not here.
