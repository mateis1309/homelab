output "vms" {
  description = "Created VMs: Proxmox ID, address and VLAN."
  value = {
    for name, vm in proxmox_virtual_environment_vm.vm : name => {
      vm_id = vm.vm_id
      ip    = local.vms[name].ip
      vlan  = local.lab.lab_zones[local.vms[name].zone].vlan
    }
  }
}
