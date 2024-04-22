# Provision AKS Cluster

#############################################################################################################################

# Create Resource Group
resource "azurerm_resource_group" "aks_rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "insights" {
  name                = "${var.prefix}-log-analytics-workspace"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  retention_in_days   = 30
}

# Manage a Log Analytics Solutions
resource "azurerm_log_analytics_solution" "container_insight" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.aks_rg.location
  resource_group_name   = azurerm_resource_group.aks_rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.insights.id
  workspace_name        = azurerm_log_analytics_workspace.insights.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# Create VNet for AKS
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  address_space       = ["10.224.0.0/12"]
}

# Create Subnet for VNet of AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "default"         ###"${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  service_endpoints    = ["Microsoft.ContainerRegistry"]
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.224.0.0/16"]
  depends_on = [azurerm_virtual_network.aks_vnet]
}

# Create Azure Kubernetes Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.prefix}-cluster"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "${var.prefix}-cluster-dns"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${var.prefix}-noderg"
  sku_tier            = "Standard"
  private_cluster_enabled = true
  azure_policy_enabled = true
  
  default_node_pool {
    name                 = "agentpool"
    vm_size              = "Standard_B2ms"      ###Standard_B2s       ###Standard_DS2_v2
    orchestrator_version = var.kubernetes_version
    zones                = [1, 2, 3]
#    enable_node_public_ip = true             ###  Will be used in Public AKS Cluster.
    enable_auto_scaling  = true
    max_count            = 1
    min_count            = 1
    node_count           = 1
    max_pods             = 110
    os_disk_type         = "Managed"
    os_disk_size_gb      = 30
    os_sku               = "Ubuntu"    ### You can select between Ubuntu and AzureLinux.
    type                 = "VirtualMachineScaleSets"
    vnet_subnet_id       = azurerm_subnet.aks_subnet.id
    upgrade_settings {
      max_surge = "33%"       ### Percentage or maximum number of nodes which will be added to the node pool while performing an upgrade. 
    }
    node_labels = {
      "nodepool-type"    = "system"
      "environment"      = var.env
      "nodepoolos"       = "linux"
#      "app"              = "system-apps" 
    } 
    tags = {
      "nodepool-type"    = "system"
      "environment"      = var.env
      "nodepoolos"       = "linux"
#      "app"              = "system-apps" 
    } 
  }

  automatic_channel_upgrade = "stable"
  node_os_channel_upgrade   = "NodeImage"
  maintenance_window_auto_upgrade {
      frequency   = "RelativeMonthly"
      interval    = 1
      duration    = 4
      day_of_week = "Sunday"
      week_index  = "First"
      start_time  = "00:00"
#      utc_offset = "+05:30"
  }
  maintenance_window_node_os {
      frequency   = "Weekly"
      interval    = 1
      duration    = 4
      day_of_week = "Sunday"
      start_time  = "00:00"
#      utc_offset = "+05:30"
  }


# Identity (System Assigned or Service Principal)
  identity {
    type = "SystemAssigned"
  }

### Storage Profile Block
  storage_profile {
    blob_driver_enabled = true                    ### Provide the boolean to enable or disable the Blob CSI Driver. Default value is false.
    disk_driver_enabled = true                    ### Provide the boolean to enable or disable the Disk CSI Driver. Default value is true.
    disk_driver_version = "v1"                    ### Disk driver version v2 is in public review. Default version is v1.
    file_driver_enabled = true                    ### Provide the boolean to enable or disable the File CSI Driver. Default value is true.
    snapshot_controller_enabled = true            ### Provide the boolean to enable or disable the Snapshot Controller. Default value is true.
  }


### Linux Profile
#  linux_profile {
#    admin_username = "ritesh"
#    ssh_key {
#      key_data = file(var.ssh_public_key)
#    }
#  }

# Network Profile
  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    load_balancer_sku = "standard"
    service_cidr        = "10.0.0.0/16"  ### Kubernetes service address range
    dns_service_ip      = "10.0.0.10"    ### Kubernetes DNS service IP address
  }

  monitor_metrics {

  }

  oms_agent {
#    enabled =  true
    log_analytics_workspace_id = azurerm_log_analytics_workspace.insights.id
  }


  tags = {
    Environment = var.env
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "autoscale_node_pool" {
# count                        = var.enable_auto_scaling ? 1 : 0
  name                         = "userpool"
  kubernetes_cluster_id        = azurerm_kubernetes_cluster.aks_cluster.id
  zones                        = [1, 2, 3]
  orchestrator_version = var.kubernetes_version
  vm_size                      = "Standard_B2ms"                ###Standard_B2s
  mode                         = "User"          ### You can select between System and User
# enable_node_public_ip = true             ###  Will be used in Public AKS Cluster.
  enable_auto_scaling          = true
  max_count            = 1
  min_count            = 1
  node_count           = 1
  max_pods             = 110
  os_disk_type         = "Managed"
  os_disk_size_gb      = 30  
  os_type              = "Linux"
  os_sku               = "Ubuntu"        ### You can select between Ubuntu and AzureLinux.
#  type                 = "VirtualMachineScaleSets"
  vnet_subnet_id       = azurerm_subnet.aks_subnet.id
  upgrade_settings {
    max_surge = "33%"       ### Percentage or maximum number of nodes which will be added to the node pool while performing an upgrade. 
  }
  node_labels = {
    "nodepool-type"    = "User"
    "environment"      = var.env
    "nodepoolos"       = "linux"
#   "app"              = "system-apps"
  }
  tags = {
    "nodepool-type"    = "User"
    "environment"      = var.env
    "nodepoolos"       = "linux"
#   "app"              = "system-apps"
  }
} 

##########################################################################################################################################

resource "azurerm_monitor_action_group" "action_group" {
  name                = "${var.prefix}-action-group"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = "global"
  short_name          = var.action_group_shortname

  email_receiver {
    name          = "GroupNotification"
    email_address = "singhriteshkumar251@gmail.com"
  }
}

resource "azurerm_monitor_metric_alert" "alert_rule1" {
  name                = "${var.prefix}-alert-rule1"
  resource_group_name = azurerm_resource_group.aks_rg.name
  scopes              = [azurerm_kubernetes_cluster.aks_cluster.id]
  description         = "Action will be triggered when Percentage CPU Utilization is greater than 0."
  auto_mitigate       = true    ### Metric Alert to be auto resolved
  frequency           = "PT5M"


  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
   
  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

resource "azurerm_monitor_metric_alert" "alert_rule2" {
  name                = "${var.prefix}-alert-rule2"
  resource_group_name = azurerm_resource_group.aks_rg.name
  scopes              = [azurerm_kubernetes_cluster.aks_cluster.id]
  auto_mitigate       = true    ### Metric Alert to be auto resolved
  frequency           = "PT5M"
  
  criteria {
    aggregation      = "Average"
    metric_name      = "node_memory_working_set_percentage"
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    operator         = "GreaterThan"
    threshold        = 100
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

#######################################################################################################
# Create Kubeconfig file 
#######################################################################################################

resource "null_resource" "kubectl" {
    provisioner "local-exec" {
        command = "az account set --subscription $(az account show --query id|tr -d '\"') && az aks get-credentials --resource-group ${azurerm_resource_group.aks_rg.name} --name ${azurerm_kubernetes_cluster.aks_cluster.name} --overwrite-existing && chmod 600 ~/.kube/config"
        interpreter = ["/bin/bash", "-c"]
    }

    depends_on = [azurerm_kubernetes_cluster.aks_cluster, azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}


resource "azurerm_role_assignment" "aks" {
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_subnet.aks_subnet.id
  depends_on = [azurerm_monitor_metric_alert.alert_rule1, azurerm_monitor_metric_alert.alert_rule2]
}
