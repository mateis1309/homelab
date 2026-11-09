variable "pve_endpoint" {
  description = "Proxmox VE API URL, without /api2/json."
  type        = string
  default     = "https://10.10.10.20:8006/"
}

variable "pve_api_token" {
  description = "API token created by the pve_host Ansible role: terraform@pve!tf=<secret>."
  type        = string
  sensitive   = true
}

variable "pve_insecure_tls" {
  description = "Skip TLS verification (self-signed Proxmox certificate)."
  type        = bool
  default     = true
}

variable "pve_node" {
  description = "Proxmox node name."
  type        = string
  default     = "pve"
}

variable "template_vm_id" {
  description = "Cloud-init template built by the pve_host Ansible role."
  type        = number
  default     = 9000
}

variable "datastore" {
  description = "Storage for VM disks and cloud-init drives."
  type        = string
  default     = "local-lvm"
}

variable "bridge" {
  description = "VLAN-aware bridge on the Proxmox host."
  type        = string
  default     = "vmbr0"
}

variable "admin_user" {
  description = "User created by cloud-init; Ansible connects as this user (matches ansible_user)."
  type        = string
  default     = "ops"
}

variable "ssh_public_key_path" {
  description = "Public key authorised for the admin user."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "lab_file" {
  description = "Network model shared with Ansible."
  type        = string
  default     = "../ansible/inventory/group_vars/all/lab.yml"
}
