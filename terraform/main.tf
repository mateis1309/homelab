# VMs are declared in ansible/inventory/group_vars/all/lab.yml (hosts with a `vm:` block).
# Terraform reads the same file Ansible does, so the VLAN, address and size of a VM
# are written down exactly once.
locals {
  lab = yamldecode(file("${path.module}/${var.lab_file}"))

  vms = { for name, host in local.lab.lab_hosts : name => host if try(host.vm, null) != null }

  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = local.vms

  name        = each.key
  description = "${each.value.description}. Managed by Terraform (github.com/mateis1309/homelab)."
  node_name   = var.pve_node
  vm_id       = each.value.vm.id
  tags        = ["homelab", "terraform", each.value.zone]

  on_boot         = true
  started         = true
  stop_on_destroy = true

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  # qemu-guest-agent is baked into the template, so Terraform can read the VM state on first boot.
  agent {
    enabled = true
    trim    = true
  }

  cpu {
    cores = each.value.vm.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.vm.memory_mb
  }

  disk {
    datastore_id = var.datastore
    interface    = "scsi0"
    size         = each.value.vm.disk_gb
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge  = var.bridge
    vlan_id = local.lab.lab_zones[each.value.zone].vlan
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  initialization {
    datastore_id = var.datastore

    ip_config {
      ipv4 {
        address = "${each.value.ip}/${split("/", local.lab.lab_zones[each.value.zone].cidr)[1]}"
        gateway = cidrhost(local.lab.lab_zones[each.value.zone].cidr, 1)
      }
    }

    dns {
      domain  = local.lab.lab_domain
      servers = [cidrhost(local.lab.lab_zones[each.value.zone].cidr, 1)]
    }

    user_account {
      username = var.admin_user
      keys     = [local.ssh_public_key]
    }
  }

  lifecycle {
    precondition {
      condition     = contains(keys(local.lab.lab_zones), each.value.zone)
      error_message = "VM ${each.key} uses zone '${each.value.zone}', which is not defined in lab_zones."
    }
  }
}
