output "name" {
  description = "List of VM names created by the module."
  value       = join(",", proxmox_virtual_environment_vm.base_vm[*].name)
}

output "ipv4_address" {
  description = "List of VM names created by the module."
  # lo is the first interface, eth0 is the second.
  value = join(",", proxmox_virtual_environment_vm.base_vm[*].ipv4_addresses[1][0])
}

output "id" {
  description = "List of VM IDs created by the module."
  value       = tolist(proxmox_virtual_environment_vm.base_vm[*].id)[0]
}

output "node_name" {
  description = "List of node names of the VM created by the module."
  value       = tolist(proxmox_virtual_environment_vm.base_vm[*].node_name)[0]
}
