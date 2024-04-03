module "aks" {
  source = "../module"
  prefix = var.prefix
  location = var.location[0]
  kubernetes_version = var.kubernetes_version[6]
  ssh_public_key = var.ssh_public_key
  action_group_shortname = var.action_group_shortname
  monitoring_namespace = var.monitoring_namespace
  k8s_management_node_rg = var.k8s_management_node_rg
  k8s_management_node_vnet = var.k8s_management_node_vnet
  k8s_management_node_vnet_id = var.k8s_management_node_vnet_id

  env = var.env[0]

}
