resource "azurerm_resource_group" "dns_rg" {
  name     = "${var.prefix}-rosource-group"
  location = var.location[0]
}

resource "azurerm_dns_zone" "dns_zone" {
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.dns_rg.name
}

resource "azurerm_dns_a_record" "record_set" {
  name                = var.a_reccord_name
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.dns_rg.name
  ttl                 = 300
  records             = var.public_ip                      ### target_resource_id  = azurerm_public_ip.vm_public_ip.id
}
