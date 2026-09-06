terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.103.0"
    }
  }
}

data "proxmox_virtual_environment_vms" "all" {
  node_name = var.node_name
}

data "proxmox_hardware_pci" "all" {
  count     = length(var.hostpcis) > 0 ? 1 : 0
  node_name = var.node_name
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
  cloudinit_vm = [for vm in data.proxmox_virtual_environment_vms.all.vms : vm if vm.name == var.cloudinit_template][0]
}

resource "proxmox_virtual_environment_vm" "base_vm" {
  node_name       = var.node_name
  name            = var.name
  tags            = concat(["terraform", var.size], var.tags)
  stop_on_destroy = true

  clone {
    vm_id = local.cloudinit_vm.vm_id
  }

  agent {
    enabled = true

    wait_for_ip {
      ipv4 = true
    }
  }

  cpu {
    cores = local.presets[var.size].cpu
  }

  memory {
    dedicated = local.presets[var.size].memory
    floating  = local.presets[var.size].memory
  }

  disk {
    datastore_id = var.root_datastore_id
    size         = local.effective_disk
    interface    = "scsi0"
  }

  dynamic "disk" {
    for_each = var.disks

    content {
      datastore_id = disk.value.datastore_id
      size         = disk.value.size
      interface    = "scsi${disk.key + 1}"
      discard      = "on"
      iothread     = true
    }
  }

  dynamic "hostpci" {
    for_each = var.hostpcis

    content {
      device = "hostpci${hostpci.key}"
      id     = coalesce(hostpci.value.id, [for device in data.proxmox_hardware_pci.all[0].devices : device.id if device.device_name == hostpci.value.device_name][0])
      pcie   = true
      rombar = hostpci.value.rombar
      xvga   = hostpci.value.xvga
    }
  }

  network_device {
    bridge   = var.bridge
    vlan_id  = var.vlan_id
    firewall = true
  }

  initialization {
    datastore_id = var.root_datastore_id

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
