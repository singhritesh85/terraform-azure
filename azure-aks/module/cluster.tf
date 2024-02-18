# Provision AKS Cluster

#############################################################################################################################

terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
  }
}

provider "azapi" {

}



data "azurerm_client_config" "current" {

}

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

# Create Azure Monitor Workspace
resource "azurerm_monitor_workspace" "azure_monitor_workspace" {
  name                = "${var.prefix}-monitor-workspace"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
}

# Create Azure Monitor Data Collection Endpoint
resource "azurerm_monitor_data_collection_endpoint" "azure_monitor_datacollection_endpoint" {
  name                = "${var.prefix}-monitor-datacollection-endpoint"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  kind                = "Linux" 
}

# Create Azure Monitor Data Collection Rule
resource "azurerm_monitor_data_collection_rule" "azure_monitor_datacollection_rule" {
  name                        = "${var.prefix}-monitor_datacollection-rule"
  resource_group_name         = azurerm_resource_group.aks_rg.name
  location                    = azurerm_resource_group.aks_rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.azure_monitor_datacollection_endpoint.id

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.azure_monitor_workspace.id
      name               = azurerm_monitor_workspace.azure_monitor_workspace.name
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = [azurerm_monitor_workspace.azure_monitor_workspace.name]
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
  name                 = "${var.prefix}-subnet"
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
    vm_size              = "Standard_B2s"             ##Standard_DS2_v2
    orchestrator_version = var.kubernetes_version
    zones                = [1, 2, 3]
#    enable_node_public_ip = true             ###  Will be used in Public AKS Cluster.
    enable_auto_scaling  = true
    max_count            = 1
    min_count            = 1
    os_disk_type         = "Managed"
    os_disk_size_gb      = 30
    os_sku               = "Ubuntu"    ### You can select between Ubuntu and AzureLinux.
    type                 = "VirtualMachineScaleSets"
    vnet_subnet_id       = azurerm_subnet.aks_subnet.id
    upgrade_settings {
      max_surge = "10%"
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
  vm_size                      = "Standard_B2s"
  mode                         = "User"          ### You can select between System and User
# enable_node_public_ip = true             ###  Will be used in Public AKS Cluster.
  enable_auto_scaling          = true
  max_count            = 1
  min_count            = 1
  os_disk_type         = "Managed"
  os_disk_size_gb      = 30  
  os_type              = "Linux"
  os_sku               = "Ubuntu"        ### You can select between Ubuntu and AzureLinux.
#  type                 = "VirtualMachineScaleSets"
  vnet_subnet_id       = azurerm_subnet.aks_subnet.id
  upgrade_settings {
    max_surge = "10%"
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


# association to a Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "azure_monitor_dcr_to_aks" {
  name                    = "${var.prefix}-dcr-to-aks"
  target_resource_id      = azurerm_kubernetes_cluster.aks_cluster.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.azure_monitor_datacollection_rule.id
}

# associate to a Data Collection Endpoint
resource "azurerm_monitor_data_collection_rule_association" "azure_monitor_dce_to_aks" {
  target_resource_id          = azurerm_kubernetes_cluster.aks_cluster.id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.azure_monitor_datacollection_endpoint.id
}

resource "random_id" "id" {
  byte_length = 2
}

resource "azurerm_dashboard_grafana" "azure_grafana" {
  name                = "${var.prefix}-grafana-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  public_network_access_enabled     = true
  deterministic_outbound_ip_enabled = false
#  api_key_enabled     = true

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.azure_monitor_workspace.id
  }
}

resource "azurerm_role_assignment" "role_azure_monitor_workspace" {
  scope                = azurerm_monitor_workspace.azure_monitor_workspace.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "role_azure_monitor_grafana" {
  scope                = azurerm_monitor_workspace.azure_monitor_workspace.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.azure_grafana.identity[0].principal_id
}

resource "azurerm_role_assignment" "grafana_admin" {
  scope                = azurerm_dashboard_grafana.azure_grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

##########################################################################################################################################

resource "azapi_resource" "NodeRecordingRulesRuleGroup" {
  type      = "Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01"
  name      = "NodeRecordingRulesRuleGroup-${azurerm_kubernetes_cluster.aks_cluster.name}"
  location  = azurerm_monitor_workspace.azure_monitor_workspace.location
  parent_id = azurerm_resource_group.aks_rg.id
  body = jsonencode({
    "properties" : {
      "scopes" : [
        azurerm_monitor_workspace.azure_monitor_workspace.id
      ],
      "clusterName" : azurerm_kubernetes_cluster.aks_cluster.name,
      "interval" : "PT1M",
      "rules": [
      {
        "record": "instance:node_num_cpu:sum",
        "expression": "count without (cpu, mode) (  node_cpu_seconds_total{job=\"node\",mode=\"idle\"})"
      },
      {
        "record": "instance:node_cpu_utilisation:rate5m",
        "expression": "1 - avg without (cpu) (  sum without (mode) (rate(node_cpu_seconds_total{job=\"node\", mode=~\"idle|iowait|steal\"}[5m])))"
      },
      {
        "record": "instance:node_load1_per_cpu:ratio",
        "expression": "(  node_load1{job=\"node\"}/  instance:node_num_cpu:sum{job=\"node\"})"
      },
      {
        "record": "instance:node_memory_utilisation:ratio",
        "expression": "1 - (  (    node_memory_MemAvailable_bytes{job=\"node\"}    or    (      node_memory_Buffers_bytes{job=\"node\"}      +      node_memory_Cached_bytes{job=\"node\"}      +      node_memory_MemFree_bytes{job=\"node\"}      +      node_memory_Slab_bytes{job=\"node\"}    )  )/  node_memory_MemTotal_bytes{job=\"node\"})"
      },
      {
        "record": "instance:node_vmstat_pgmajfault:rate5m",
        "expression": "rate(node_vmstat_pgmajfault{job=\"node\"}[5m])"
      },
      {
        "record": "instance_device:node_disk_io_time_seconds:rate5m",
        "expression": "rate(node_disk_io_time_seconds_total{job=\"node\", device!=\"\"}[5m])"
      },
      {
        "record": "instance_device:node_disk_io_time_weighted_seconds:rate5m",
        "expression": "rate(node_disk_io_time_weighted_seconds_total{job=\"node\", device!=\"\"}[5m])"
      },
      {
        "record": "instance:node_network_receive_bytes_excluding_lo:rate5m",
        "expression": "sum without (device) (  rate(node_network_receive_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
      },
      {
        "record": "instance:node_network_transmit_bytes_excluding_lo:rate5m",
        "expression": "sum without (device) (  rate(node_network_transmit_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
      },
      {
        "record": "instance:node_network_receive_drop_excluding_lo:rate5m",
        "expression": "sum without (device) (  rate(node_network_receive_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
      },
      {
        "record": "instance:node_network_transmit_drop_excluding_lo:rate5m",
        "expression": "sum without (device) (  rate(node_network_transmit_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
      }
    ]
    }
  })
 
#  schema_validation_enabled = false
#  ignore_missing_property   = false
}
 
resource "azapi_resource" "KubernetesReccordingRulesRuleGroup" {
  type      = "Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01"
  name      = "KubernetesReccordingRulesRuleGroup-${azurerm_kubernetes_cluster.aks_cluster.name}"
  location  = azurerm_monitor_workspace.azure_monitor_workspace.location
  parent_id = azurerm_resource_group.aks_rg.id
  body = jsonencode({
    "properties" : {
      "scopes" : [
        azurerm_monitor_workspace.azure_monitor_workspace.id
      ],
      "clusterName" : azurerm_kubernetes_cluster.aks_cluster.name,
      "interval" : "PT1M",
      "rules": [
      {
        "record": "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate",
        "expression": "sum by (cluster, namespace, pod, container) (  irate(container_cpu_usage_seconds_total{job=\"cadvisor\", image!=\"\"}[5m])) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (  1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=\"\"}))"
      },
      {
        "record": "node_namespace_pod_container:container_memory_working_set_bytes",
        "expression": "container_memory_working_set_bytes{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
      },
      {
        "record": "node_namespace_pod_container:container_memory_rss",
        "expression": "container_memory_rss{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
      },
      {
        "record": "node_namespace_pod_container:container_memory_cache",
        "expression": "container_memory_cache{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
      },
      {
        "record": "node_namespace_pod_container:container_memory_swap",
        "expression": "container_memory_swap{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
      },
      {
        "record": "cluster:namespace:pod_memory:active:kube_pod_container_resource_requests",
        "expression": "kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
      },
      {
        "record": "namespace_memory:kube_pod_container_resource_requests:sum",
        "expression": "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
      },
      {
        "record": "cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests",
        "expression": "kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
      },
      {
        "record": "namespace_cpu:kube_pod_container_resource_requests:sum",
        "expression": "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
      },
      {
        "record": "cluster:namespace:pod_memory:active:kube_pod_container_resource_limits",
        "expression": "kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
      },
      {
        "record": "namespace_memory:kube_pod_container_resource_limits:sum",
        "expression": "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
      },
      {
        "record": "cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits",
        "expression": "kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ( (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1) )"
      },
      {
        "record": "namespace_cpu:kube_pod_container_resource_limits:sum",
        "expression": "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
      },
      {
        "record": "namespace_workload_pod:kube_pod_owner:relabel",
        "expression": "max by (cluster, namespace, workload, pod) (  label_replace(    label_replace(      kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"ReplicaSet\"},      \"replicaset\", \"$1\", \"owner_name\", \"(.*)\"    ) * on(replicaset, namespace) group_left(owner_name) topk by(replicaset, namespace) (      1, max by (replicaset, namespace, owner_name) (        kube_replicaset_owner{job=\"kube-state-metrics\"}      )    ),    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))",
        "labels": {
          "workload_type": "deployment"
        }
      },
      {
        "record": "namespace_workload_pod:kube_pod_owner:relabel",
        "expression": "max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"DaemonSet\"},    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))",
        "labels": {
          "workload_type": "daemonset"
        }
      },
      {
        "record": "namespace_workload_pod:kube_pod_owner:relabel",
        "expression": "max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"StatefulSet\"},    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))",
        "labels": {
          "workload_type": "statefulset"
        }
      },
      {
        "record": "namespace_workload_pod:kube_pod_owner:relabel",
        "expression": "max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"Job\"},    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))",
        "labels": {
          "workload_type": "job"
        }
      },
      {
        "record": ":node_memory_MemAvailable_bytes:sum",
        "expression": "sum(  node_memory_MemAvailable_bytes{job=\"node\"} or  (    node_memory_Buffers_bytes{job=\"node\"} +    node_memory_Cached_bytes{job=\"node\"} +    node_memory_MemFree_bytes{job=\"node\"} +    node_memory_Slab_bytes{job=\"node\"}  )) by (cluster)"
      },
      {
        "record": "cluster:node_cpu:ratio_rate5m",
        "expression": "sum(rate(node_cpu_seconds_total{job=\"node\",mode!=\"idle\",mode!=\"iowait\",mode!=\"steal\"}[5m])) by (cluster) /count(sum(node_cpu_seconds_total{job=\"node\"}) by (cluster, instance, cpu)) by (cluster)"
      }
    ]
    }
  })
 
#  schema_validation_enabled = false
#  ignore_missing_property   = false
}

#resource "azapi_update_resource" "example" {
#  type        = "Microsoft.ContainerService/managedClusters@2023-05-02-preview"
#  resource_id = azurerm_kubernetes_cluster.aks_cluster.id

#  body = jsonencode({
#    properties = {
#      networkProfile = {
#        monitoring = {
#          enabled = true
#        }
#      }
#    }
#  })
  
#  depends_on = [ 
#    azurerm_monitor_data_collection_rule_association.azure_monitor_dcr_to_aks,
#    azurerm_monitor_data_collection_rule_association.azure_monitor_dce_to_aks,
#  ]
#}


################################################################################################################

resource "azurerm_monitor_alert_prometheus_rule_group" "noderecordingrules" {
  # https://github.com/Azure/prometheus-collector/blob/kaveesh/windows_recording_rules/AddonArmTemplate/WindowsRecordingRuleGroupTemplate/WindowsRecordingRules.json
  name                = "NodeRecordingRulesRuleGroup-Win-${azurerm_kubernetes_cluster.aks_cluster.name}"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  cluster_name        = azurerm_kubernetes_cluster.aks_cluster.name
  description         = "Kubernetes Recording Rules RuleGroup for Win"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.azure_monitor_workspace.id]
 
  rule {
    enabled    = true
    record     = "node:windows_node:sum"
    expression = <<EOF
count (windows_system_system_up_time{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_num_cpu:sum"
    expression = <<EOF
count by (instance) (sum by (instance, core) (windows_cpu_time_total{job="windows-exporter"}))
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_cpu_utilisation:avg5m"
    expression = <<EOF
1 - avg(rate(windows_cpu_time_total{job="windows-exporter",mode="idle"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_cpu_utilisation:avg5m"
    expression = <<EOF
1 - avg by (instance) (rate(windows_cpu_time_total{job="windows-exporter",mode="idle"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_memory_utilisation:"
    expression = <<EOF
1 -sum(windows_memory_available_bytes{job="windows-exporter"})/sum(windows_os_visible_memory_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_memory_MemFreeCached_bytes:sum"
    expression = <<EOF
sum(windows_memory_available_bytes{job="windows-exporter"} + windows_memory_cache_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_totalCached_bytes:sum"
    expression = <<EOF
(windows_memory_cache_bytes{job="windows-exporter"} + windows_memory_modified_page_list_bytes{job="windows-exporter"} + windows_memory_standby_cache_core_bytes{job="windows-exporter"} + windows_memory_standby_cache_normal_priority_bytes{job="windows-exporter"} + windows_memory_standby_cache_reserve_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_memory_MemTotal_bytes:sum"
    expression = <<EOF
sum(windows_os_visible_memory_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_bytes_available:sum"
    expression = <<EOF
sum by (instance) ((windows_memory_available_bytes{job="windows-exporter"}))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_bytes_total:sum"
    expression = <<EOF
sum by (instance) (windows_os_visible_memory_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_utilisation:"
    expression = <<EOF
(node:windows_node_memory_bytes_total:sum - node:windows_node_memory_bytes_available:sum) / scalar(sum(node:windows_node_memory_bytes_total:sum))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_utilisation:"
    expression = <<EOF
1 - (node:windows_node_memory_bytes_available:sum / node:windows_node_memory_bytes_total:sum)
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_swap_io_pages:irate"
    expression = <<EOF
irate(windows_memory_swap_page_operations_total{job="windows-exporter"}[5m])
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_disk_utilisation:avg_irate"
    expression = <<EOF
avg(irate(windows_logical_disk_read_seconds_total{job="windows-exporter"}[5m]) + irate(windows_logical_disk_write_seconds_total{job="windows-exporter"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_disk_utilisation:avg_irate"
    expression = <<EOF
avg by (instance) ((irate(windows_logical_disk_read_seconds_total{job="windows-exporter"}[5m]) + irate(windows_logical_disk_write_seconds_total{job="windows-exporter"}[5m])))
EOF
  }
}
 
resource "azurerm_monitor_alert_prometheus_rule_group" "nodeandkubernetesrules" {
  # https://github.com/Azure/prometheus-collector/blob/kaveesh/windows_recording_rules/AddonArmTemplate/WindowsRecordingRuleGroupTemplate/WindowsRecordingRules.json
  name                = "NodeAndKubernetesRecordingRulesRuleGroup-Win-${azurerm_kubernetes_cluster.aks_cluster.name}"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  cluster_name        = azurerm_kubernetes_cluster.aks_cluster.name
  description         = "Kubernetes Recording Rules RuleGroup for Win"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.azure_monitor_workspace.id]
 
  rule {
    enabled    = true
    record     = "node:windows_node_filesystem_usage:"
    expression = <<EOF
max by (instance,volume)((windows_logical_disk_size_bytes{job="windows-exporter"} - windows_logical_disk_free_bytes{job="windows-exporter"}) / windows_logical_disk_size_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_filesystem_avail:"
    expression = <<EOF
max by (instance, volume) (windows_logical_disk_free_bytes{job="windows-exporter"} / windows_logical_disk_size_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_net_utilisation:sum_irate"
    expression = <<EOF
sum(irate(windows_net_bytes_total{job="windows-exporter"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_net_utilisation:sum_irate"
    expression = <<EOF
sum by (instance) ((irate(windows_net_bytes_total{job="windows-exporter"}[5m])))
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_net_saturation:sum_irate"
    expression = <<EOF
sum(irate(windows_net_packets_received_discarded_total{job="windows-exporter"}[5m])) + sum(irate(windows_net_packets_outbound_discarded_total{job="windows-exporter"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_net_saturation:sum_irate"
    expression = <<EOF
sum by (instance) ((irate(windows_net_packets_received_discarded_total{job="windows-exporter"}[5m]) + irate(windows_net_packets_outbound_discarded_total{job="windows-exporter"}[5m])))
EOF
  }
  rule {
    enabled    = true
    record     = "windows_pod_container_available"
    expression = <<EOF
windows_container_available{job="windows-exporter"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics"}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "windows_container_total_runtime"
    expression = <<EOF
windows_container_cpu_usage_seconds_total{job="windows-exporter"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics"}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "windows_container_memory_usage"
    expression = <<EOF
windows_container_memory_usage_commit_bytes{job="windows-exporter"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics"}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "windows_container_private_working_set_usage"
    expression = <<EOF
windows_container_memory_usage_private_working_set_bytes{job="windows-exporter"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics"}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "windows_container_network_received_bytes_total"
    expression = <<EOF
windows_container_network_receive_bytes_total{job="windows-exporter"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics"}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "windows_container_network_transmitted_bytes_total"
    expression = <<EOF
windows_container_network_transmit_bytes_total{job="windows-exporter"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics"}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "kube_pod_windows_container_resource_memory_request"
    expression = <<EOF
max by (namespace, pod, container) (kube_pod_container_resource_requests{resource="memory",job="kube-state-metrics"}) * on(container,pod,namespace) (windows_pod_container_available)
EOF
  }
  rule {
    enabled    = true
    record     = "kube_pod_windows_container_resource_memory_limit"
    expression = <<EOF
kube_pod_container_resource_limits{resource="memory",job="kube-state-metrics"} * on(container,pod,namespace) (windows_pod_container_available)
EOF
  }
  rule {
    enabled    = true
    record     = "kube_pod_windows_container_resource_cpu_cores_request"
    expression = <<EOF
max by (namespace, pod, container) ( kube_pod_container_resource_requests{resource="cpu",job="kube-state-metrics"}) * on(container,pod,namespace) (windows_pod_container_available)
EOF
  }
  rule {
    enabled    = true
    record     = "kube_pod_windows_container_resource_cpu_cores_limit"
    expression = <<EOF
kube_pod_container_resource_limits{resource="cpu",job="kube-state-metrics"} * on(container,pod,namespace) (windows_pod_container_available)
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_pod_container:windows_container_cpu_usage_seconds_total:sum_rate"
    expression = <<EOF
sum by (namespace, pod, container) (rate(windows_container_total_runtime{}[5m]))
EOF
  }
}

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
