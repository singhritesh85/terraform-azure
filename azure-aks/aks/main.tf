module "aks" {
  source = "../module"
  prefix = var.prefix
  location = var.location[0]
  kubernetes_version = var.kubernetes_version[6]
  ssh_public_key = var.ssh_public_key
  action_group_shortname = var.action_group_shortname
  env = var.env[0]

}
