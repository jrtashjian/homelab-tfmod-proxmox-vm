terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.101.0"
    }
  }
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
}

data "proxmox_virtual_environment_datastores" "datastores" {
  node_name = var.node_name
}

locals {
  datastore_iso = [
    for ds in data.proxmox_virtual_environment_datastores.datastores.datastores : ds.id
    if contains(ds.content_types, "iso")
  ][0]

  datastore_snippets = [
    for ds in data.proxmox_virtual_environment_datastores.datastores.datastores : ds.id
    if contains(ds.content_types, "snippets")
  ][0]
}

data "proxmox_virtual_environment_file" "debian_cloud_image" {
  node_name    = var.node_name
  datastore_id = local.datastore_iso

  content_type = "iso"
  file_name    = "debian-13-genericcloud-amd64.img"
}

data "proxmox_virtual_environment_file" "debian_vendor_config" {
  node_name    = var.node_name
  datastore_id = local.datastore_snippets

  content_type = "snippets"
  file_name    = "debian-vendor-config.yml"
}

resource "proxmox_virtual_environment_vm" "base_vm" {
  node_name = var.node_name
  tags      = concat(["terraform", var.size], var.tags)

  name = var.vm_name

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    type  = "x86-64-v2-AES"
    cores = local.presets[var.size].cpu
  }

  memory {
    dedicated = local.presets[var.size].memory
  }

  disk {
    datastore_id = "machines"
    file_id      = data.proxmox_virtual_environment_file.debian_cloud_image.id
    size         = local.effective_disk
    interface    = "scsi0"
    discard      = "on"
    iothread     = true
  }

  scsi_hardware = "virtio-scsi-single"
  boot_order    = ["scsi0"]

  network_device {
    firewall = true
  }

  vga {
    type = "serial0"
  }

  serial_device {}

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

    vendor_data_file_id = data.proxmox_virtual_environment_file.debian_vendor_config.id
  }
}
