resource "azurerm_resource_group" "container_registry_rg" {
  name     = "${var.prefix}-containerregistry-rg"
  location = var.location[0]
}

resource "azurerm_container_registry" "acr" {
  name                          = "${var.prefix}"
  resource_group_name           = azurerm_resource_group.container_registry_rg.name
  location                      = azurerm_resource_group.container_registry_rg.location
  sku                           = var.acr_sku
  public_network_access_enabled = true 
  admin_enabled                 = var.admin_enabled
}

