# Proxmox VM Module

Terraform module to create reproducible Debian cloud-init VMs on Proxmox with preset sizes.

## Usage

```hcl
module "vm" {
  source = "./modules/vm"

  size               = "medium"
  vm_name            = "my-app"
  node_name          = "pve1"
  ipv4_address       = "192.168.10.50/24"
  ipv4_gateway       = "192.168.10.1"
  ansible_user       = "ansible"
  ansible_pass       = var.ansible_pass
  ansible_public_key = var.ansible_public_key
}
```

## Available Sizes

### Standard

| Size     | CPU | RAM    | Root Disk |
|----------|-----:|-------:|----------:|
| `nano`   | 1    | 1 GB   | 8 GB      |
| `small`  | 1    | 2 GB   | 8 GB      |
| `medium` | 2    | 4 GB   | 12 GB     |
| `large`  | 4    | 8 GB   | 16 GB     |
| `xlarge` | 6    | 16 GB  | 24 GB     |

### High Memory

| Size             | CPU | RAM    | Root Disk |
|------------------|-----:|-------:|----------:|
| `highmem-medium` | 2    | 24 GB  | 16 GB     |
| `highmem-large`  | 4    | 48 GB  | 24 GB     |

### High CPU (Compute)

| Size             | CPU | RAM    | Root Disk |
|------------------|-----:|-------:|----------:|
| `compute-large`  | 8    | 16 GB  | 16 GB     |
| `compute-xlarge` | 16   | 32 GB  | 24 GB     |

## Variables

| Name                  | Type           | Default     | Description |
|-----------------------|----------------|-------------|-------------|
| `node_name`           | string         | -           | Proxmox node name |
| `vm_name`             | string         | -           | Hostname of the VM |
| `size`                | string         | `"small"`   | Preset size (see tables above) |
| `disk_size`           | number         | `0`         | Root disk size in GB; `0` uses the preset value |
| `ipv4_address`        | string         | `"dhcp"`    | IPv4 address with CIDR or `"dhcp"` |
| `ipv4_gateway`        | string         | `""`        | IPv4 gateway (required for static IP) |
| `ansible_user`        | string         | -           | User account created via cloud-init |
| `ansible_pass`        | string         | -           | User password (sensitive) |
| `ansible_public_key`  | string         | -           | SSH public key for the user account |
| `tags`                | list(string)   | `[]`        | Additional tags to apply to the VM |


## Requirements

- Proxmox provider `bpg/proxmox` ≥ 0.101.0