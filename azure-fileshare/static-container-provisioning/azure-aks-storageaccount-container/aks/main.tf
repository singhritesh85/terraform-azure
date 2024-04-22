module "aks" {
  source = "../module"
  prefix = var.prefix
  location = var.location[0]
  kubernetes_version = var.kubernetes_version[6]
  ssh_public_key = var.ssh_public_key
  action_group_shortname = var.action_group_shortname
  account_tier = var.account_tier[0]    ### For BlockBlobStorage and FileStorage accounts only Premium is valid option.
  account_replication_type = var.account_replication_type[2]
  min_tls_version = var.min_tls_version[2]
  access_tier = var.access_tier[0]
  container_name = var.container_name
  container_access_type = var.container_access_type[1]
  routing_choice = var.routing_choice[1]
  container_delete_retaintion = var.container_delete_retaintion
  blob_delete_retaintion = var.blob_delete_retaintion
  env = var.env[0]

}
