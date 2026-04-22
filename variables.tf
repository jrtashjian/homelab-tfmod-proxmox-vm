variable "node_name" {
  description = "The name of the node to create the VM on"
  type        = string
}

variable "vm_name" {
  description = "The name of the VM to create"
  type        = string
}

variable "cloudinit_template" {
  description = "The name of the cloudinit template to clone from"
  type        = string
  default     = "cloudinit-debian-13-trixie"
}

variable "size" {
  description = "The size of the VM (nano, small, medium, large, xlarge, highmem-medium, highmem-large, compute-large, compute-xlarge)"
  type        = string
  default     = "small"

  validation {
    condition     = contains(["nano", "small", "medium", "large", "xlarge", "highmem-medium", "highmem-large", "compute-large", "compute-xlarge"], var.size)
    error_message = "Size must be one of: nano, small, medium, large, xlarge, highmem-medium, highmem-large, compute-large, compute-xlarge"
  }
}

variable "disk_size" {
  description = "Root disk size in GB. Defaults to preset value."
  type        = number
  default     = 0 # 0 = use preset
}

variable "disks" {
  description = "Additional disks to attach to the VM"
  type = list(object({
    datastore_id = string
    size         = number
  }))
  default = []
}

variable "root_datastore_id" {
  description = "The datastore ID for the root disk"
  type        = string
  default     = "machines"
}

variable "hostpcis" {
  description = "Host PCI devices to attach to the VM"
  type = list(object({
    device_name = string
    id          = optional(string)
    rombar      = optional(bool, true)
    xvga        = optional(bool, false)
  }))
  default = []
}

variable "ipv4_address" {
  description = "The IPv4 address to assign to the VM"
  type        = string
  default     = "dhcp"
}

variable "ipv4_gateway" {
  description = "The IPv4 gateway to assign to the VM"
  type        = string
  default     = ""
}

variable "ansible_user" {
  description = "Ansible user"
  type        = string
}

variable "ansible_pass" {
  description = "Ansible password"
  type        = string
  sensitive   = true
}

variable "ansible_public_key" {
  description = "Ansible public key"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the VM"
  type        = list(string)
  default     = []
}
