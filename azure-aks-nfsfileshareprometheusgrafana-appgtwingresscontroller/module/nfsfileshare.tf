###############################################################################################
# Peering vnet of Terraform-Server or k8s-management-node's vnet with AKS vnet 
###############################################################################################

resource "azurerm_virtual_network_peering" "peer1" {
  name                      = "peer1"
  resource_group_name       = var.k8s_management_node_rg
  virtual_network_name      = var.k8s_management_node_vnet
  remote_virtual_network_id = azurerm_virtual_network.aks_vnet.id
 
  depends_on = [null_resource.kubectl]
}

resource "azurerm_virtual_network_peering" "peer2" {
  name                      = "peer2"
  resource_group_name       = azurerm_resource_group.aks_rg.name
  virtual_network_name      = azurerm_virtual_network.aks_vnet.name
  remote_virtual_network_id = var.k8s_management_node_vnet_id

  depends_on = [null_resource.kubectl]
}

# Create vnet link of Terraform-Server or k8s-management-node's vnet for private dns zone
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link2" {
  name                  = "tachobell-${random_id.id2.hex}"
  resource_group_name   = azurerm_resource_group.aks_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.k8s_management_node_vnet_id

  depends_on = [null_resource.kubectl] 
}

###############################################################################################
# Provider for Kubernetes and helm
###############################################################################################

data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = azurerm_kubernetes_cluster.aks_cluster.name 
  resource_group_name = azurerm_resource_group.aks_rg.name 
}

provider "kubernetes" {
  host = data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host

  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host = data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host

    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate)
  }
}

#################################################################################################
# Create Kubernetes Namespace
#################################################################################################

resource "kubernetes_namespace" "monitor_namespace" {

  metadata {
    name = var.monitoring_namespace
  }

  depends_on = [azurerm_virtual_network_peering.peer1, azurerm_virtual_network_peering.peer2, azurerm_private_dns_zone_virtual_network_link.vnet_link2]
}

###############################################################################################################################
#Create Storage Class
###############################################################################################################################

resource "kubernetes_storage_class" "azurefile" {
  metadata {
    name = "azurefile-csi-nfs"
  }
  storage_provisioner = "file.csi.azure.com"
  volume_binding_mode = "Immediate"
  reclaim_policy      = "Retain"
  allow_volume_expansion = true
  parameters = {
    skuName       = "Premium_LRS"
    protocol      = "nfs"
    shareName     = "mederma"
  }
  mount_options = ["nconnect=4", "noresvport", "actimeo=30"]

  depends_on = [kubernetes_namespace.monitor_namespace]
}

###############################################################################################################################
#Install Prometheus using Helm 
###############################################################################################################################

resource "helm_release" "prometheus" {
  name       = "prometheus"
  chart      = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "25.17.0"
  namespace  = var.monitoring_namespace

  set {
    name  = "alertmanager.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = true
  }

  set {
    name  = "alertmanager.persistence.enabled"                     ###"alertmanager.persistentVolume.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.storageClass"
    value = "azurefile-csi-nfs"        
  }

  set {
    name  = "server.persistentVolume.size"
    value = "35Gi"
  }

  set {
    name  = "alertmanager.persistence.storageClass"                ###"alertmanager.persistentVolume.storageClass"
    value = "azurefile-csi-nfs"        
  }

  set {
    name  = "alertmanager.persistence.size"  
    value = "20Gi"   
  }

  depends_on = [kubernetes_storage_class.azurefile]

}

###############################################################################################################################
#Install Grafana using Helm
###############################################################################################################################

resource "helm_release" "grafana" {
  name       = "grafana"
  chart      = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  version    = "7.3.6"
  namespace  = var.monitoring_namespace

  set {
    name  = "persistence.enabled"
    value = true
  }

  set {
    name  = "persistence.storageClassName"
    value = "azurefile-csi-nfs"
  }

  set {
    name  = "persistence.size"
    value = "35Gi"
  }

  set {
    name  = "initChownData.enabled"
    value = false
  }

  set {
    name  = "adminPassword"
    value = "subje"
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  values = [
    file("${path.module}/grafana.yaml"),
  ]

 depends_on = [helm_release.prometheus]
#  depends_on = [kubernetes_namespace.monitor_namespace, kubernetes_persistent_volume.pv_grafana]
}
