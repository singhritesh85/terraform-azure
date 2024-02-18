output "public_ip_address" {
  description = "Public IP Address of the VM Created"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "network_interface_private_ip" {
  description = "Private IP Address of the VM Created"
  value       = azurerm_network_interface.vnet_interface.private_ip_address
}
