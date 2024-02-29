provider "azurerm" {
  subscription_id = "51283936-af44-49c6-9a24-f1cbdc17915d"
  tenant_id = "8a0fce19-3824-4678-8769-b6c8e37a33ff"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true    ### All the Resources within the Resource Group must be deleted before deleting the Resource Group.
    }
  }
}

