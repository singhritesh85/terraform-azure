#############################################################################
prefix = "aks"
location = ["East US", "East US 2", "Central India", "Central US"]
kubernetes_version = ["1.26.6", "1.26.10", "1.27.3", "1.27.7", "1.28.0", "1.28.3", "1.28.5", "1.29.0", "1.29.2"]
ssh_public_key = "ssh-key"
action_group_shortname = "aks-action"
monitoring_namespace = "monitoring"
k8s_management_node_rg = "ritesh"
k8s_management_node_vnet = "Terraform-Server-vnet"
k8s_management_node_vnet_id = "/subscriptions/51283936-af44-49c6-9a24-f1cbdc17915d/resourceGroups/ritesh/providers/Microsoft.Network/virtualNetworks/Terraform-Server-vnet"
env = ["dev", "stage", "prod"]
