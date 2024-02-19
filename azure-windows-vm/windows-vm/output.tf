output "azure_vm_public_ip" {
  value = module.azure_vm.public_ip_address
}

output "azure_vm_private_ip" {
  value = module.azure_vm.network_interface_private_ip
}
