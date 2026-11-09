terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.121"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pve_endpoint
  api_token = var.pve_api_token
  # Proxmox ships a self-signed certificate. Set false after installing a trusted one.
  insecure = var.pve_insecure_tls
}
