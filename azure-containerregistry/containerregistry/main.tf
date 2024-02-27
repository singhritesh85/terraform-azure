module "azure_container_registry" {
  source = "../module"
  prefix = var.prefix
  location = var.location
  acr_sku = var.acr_sku[1]
  admin_enabled = var.admin_enabled
 
}
