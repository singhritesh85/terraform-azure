output "resource_group_name" {
  value = azurerm_resource_group.mederma.name
}


output "subnet_id" {
  value = azurerm_subnet.vnet_subnet.id 
}
