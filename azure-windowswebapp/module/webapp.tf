resource "azurerm_resource_group" "webapp_resource_group" {
  name     = "${var.prefix}-resource-goup"
  location = var.location[0]
 
  tags = {
    environment = var.env
  }

}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "${var.prefix}-logworkspace"
  location            = azurerm_resource_group.webapp_resource_group.location
  resource_group_name = azurerm_resource_group.webapp_resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = var.env
  }

}


resource "azurerm_application_insights" "webapp_insight" {
  name                = "${var.prefix}-appinsights"
  location            = azurerm_resource_group.webapp_resource_group.location
  resource_group_name = azurerm_resource_group.webapp_resource_group.name
  workspace_id        = azurerm_log_analytics_workspace.example.id
  application_type    = "web"        ### java


#  tags = {
#    "hidden-link:/subscriptions/51283936-af44-49c6-9a24-f1cbdc17915d/resourceGroups/azurerm_resource_group.webapp_resource_group.name/providers/Microsoft.Web/sites/azurerm_windows_web_app.webapp_windows.name": "Resource"
#  }
  tags = {
    environment = var.env
  }

}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "${var.prefix}-plan"
  resource_group_name = azurerm_resource_group.webapp_resource_group.name
  location            = azurerm_resource_group.webapp_resource_group.location
  os_type             = "Windows"
  sku_name            = var.serviceplan_skuname
  zone_balancing_enabled = true           ### Depending on the sku plan please select enable or disable zone balancing
  
  tags = {
    environment = var.env
  }
}

resource "azurerm_windows_web_app" "webapp_windows" {
  name                = "${var.prefix}-webapp"
  resource_group_name = azurerm_resource_group.webapp_resource_group.name
  location            = azurerm_service_plan.app_service_plan.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  site_config {
    always_on = true
    application_stack {
      current_stack = var.current_stack     ### "dotnet"
      dotnet_version = var.dotnet_version   ### "v6.0"
    }
  }

  public_network_access_enabled = true   ### Should public network is accessible for the WebApp. Default value is true.

  tags = {
    environment = var.env
  }

  ### GitHub Actions Settings Continuous Deployment is disabled.

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = "${azurerm_application_insights.webapp_insight.instrumentation_key}"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"      = "${azurerm_application_insights.webapp_insight.connection_string}"
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }
}

