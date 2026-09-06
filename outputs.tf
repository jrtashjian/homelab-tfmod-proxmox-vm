output "name" {
  description = "Name of the VM."
  value       = proxmox_virtual_environment_vm.base_vm.name
}

output "ipv4_address" {
  description = "Primary IPv4 address of the VM."
  value       = proxmox_virtual_environment_vm.base_vm.ipv4_addresses[1][0]
}

output "id" {
  description = "ID of the VM."
  value       = proxmox_virtual_environment_vm.base_vm.id
}

output "node_name" {
  description = "Node name of the VM."
  value       = proxmox_virtual_environment_vm.base_vm.node_name
}
