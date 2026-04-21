terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.101.0"
    }
  }
}

data "proxmox_virtual_environment_vms" "node" {
  node_name = var.node_name
}

output "template" {
  value = [for vm in data.proxmox_virtual_environment_vms.node.vms : vm.vm_id if vm.name == var.cloudinit_template][0]
}

locals {
  presets = {
    # Standard configurations.
    nano   = { cpu = 1, memory = 1024, disk = 8 }
    small  = { cpu = 1, memory = 2048, disk = 8 }
    medium = { cpu = 2, memory = 4096, disk = 12 }
    large  = { cpu = 4, memory = 8192, disk = 16 }
    xlarge = { cpu = 6, memory = 16384, disk = 24 }

    # High Memory configurations.
    highmem-medium = { cpu = 2, memory = 24576, disk = 16 }
    highmem-large  = { cpu = 4, memory = 49152, disk = 24 }

    # High CPU configurations.
    compute-large  = { cpu = 8, memory = 16384, disk = 16 }
    compute-xlarge = { cpu = 16, memory = 32768, disk = 24 }
  }

  # Use override if provided, otherwise preset
  effective_disk = var.disk_size > 0 ? var.disk_size : local.presets[var.size].disk

  # Find the cloudinit template VM to clone from.
  cloudinit_vm = [for vm in data.proxmox_virtual_environment_vms.node.vms : vm if vm.name == var.cloudinit_template][0]
}

resource "proxmox_virtual_environment_vm" "base_vm" {
  node_name = var.node_name
  tags      = concat(["terraform", var.size], var.tags)

  name = var.vm_name

  clone {
    vm_id = local.cloudinit_vm.vm_id
  }

  cpu {
    cores = local.presets[var.size].cpu
  }

  memory {
    dedicated = local.presets[var.size].memory
  }

  disk {
    datastore_id = "machines"
    size         = local.effective_disk
    interface    = "scsi0"
  }

  initialization {
    datastore_id = "machines"

    user_account {
      username = var.ansible_user
      password = var.ansible_pass
      keys     = [var.ansible_public_key]
    }

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
      }
    }
  }
}
