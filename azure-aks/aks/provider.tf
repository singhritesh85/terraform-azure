#terraform {
#  required_providers {
#    azurerm = {
#      source  = "registry.terraform.io/hashicorp/azurerm"
#    }
#    kubernetes = {
#      source  = "registry.terraform.io/hashicorp/kubernetes"
#    }
#    # Used to deploy kubectl_manifest resource
#    kubectl = {
#      source  = "gavinbunney/kubectl"
#    }
#    helm = {
#      source  = "registry.terraform.io/hashicorp/helm"
#    }
#    random = {
#      source  = "registry.terraform.io/hashicorp/random"
#    }
#  } 
#}

provider "azurerm" {
  subscription_id = "51283936-af44-49c6-9a24-f1cbdc17915d"
  tenant_id = "8a0fce19-3824-4678-8769-b6c8e37a33ff"
  features {
    
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = true    ### All the Resources within the Resource Group must be deleted before deleting the Resource Group.
    }
  }
}

