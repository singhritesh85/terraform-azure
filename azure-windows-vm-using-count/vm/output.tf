output "resource_group_name" {
  value = module.azurevnet.resource_group_name
}

output "subnet_id" {
  value = module.azurevnet.subnet_id        # azurerm_subnet.vnet_subnet
}

output "azure_vm_public_ip" {
  value = module.azurevm.*.public_ip_address
}

output "azure_vm_private_ip" {
  value = module.azurevm.*.network_interface_private_ip
}
