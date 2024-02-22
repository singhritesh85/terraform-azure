module "azure_sa" {
  source = "../module"
  prefix = var.prefix
  location = var.location
  account_tier = var.account_tier[0]    ### For BlockBlobStorage and FileStorage accounts only Premium is valid option.
  account_replication_type = var.account_replication_type[2]
  env = var.env[0]
  min_tls_version = var.min_tls_version[2]
  access_tier = var.access_tier[0]
  routing_choice = var.routing_choice[1]
  container_delete_retaintion = var.container_delete_retaintion
  blob_delete_retaintion = var.blob_delete_retaintion
}
