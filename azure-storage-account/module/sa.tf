resource "azurerm_resource_group" "azure_sa_rg" {
  name     = "${var.prefix}-resource-group"
  location = var.location[0]
}

resource "random_id" "id" {
  byte_length = 4
}

resource "azurerm_storage_account" "azure_sa" {
  name                      = "${var.prefix}${random_id.id.hex}"
  resource_group_name       = azurerm_resource_group.azure_sa_rg.name
  location                  = azurerm_resource_group.azure_sa_rg.location
  account_tier              = var.account_tier
  account_replication_type  = var.account_replication_type
  min_tls_version           = var.min_tls_version        ### Default TLS Version is TLS1_2.
  shared_access_key_enabled = true
  enable_https_traffic_only = true
# allowed_copy_scope        = "AAD"   ### Possible values are AAD and PrivateLink                      
  access_tier               = var.access_tier
  public_network_access_enabled = true
  
  routing {
    choice = var.routing_choice
  }
  
  blob_properties {
    delete_retention_policy {
      days = var.blob_delete_retaintion
    }
    container_delete_retention_policy {
      days = var.container_delete_retaintion
    }  
  }

  ### For encryption by default Microsoft-managed keys is used.

  infrastructure_encryption_enabled = false

  tags = {
    environment = var.env
  }
}
