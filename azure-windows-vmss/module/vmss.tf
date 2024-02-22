############################# Azure Virtual Machine Scale Set with the Uniform Orchestration Mode #########################################
      
resource "azurerm_windows_virtual_machine_scale_set" "vm_scale_set" {
  name                = "mytestscaleset-1"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name

  instances            = 2
  admin_username       = "ritesh"
  admin_password       = "Password@#795"
  computer_name_prefix = "${var.prefix}"
# custom_data            = filebase64("custom_data.ps1")
  sku                  = "Standard_B2s"
  
  overprovision        = false    ###  Default value is true 

  # automatic rolling upgrade
  upgrade_mode = "Automatic"   ### "Rolling"     ### Can be used for Ubuntu or Windows Server Operating Systems, default value is Manual. 

# automatic_os_upgrade_policy {
#   disable_automatic_rollback = false
#   enable_automatic_os_upgrade = false  ### You can set it to false if needed.
# }

# rolling_upgrade_policy {
#   max_batch_instance_percent              = 20
#   max_unhealthy_instance_percent          = 20
#   max_unhealthy_upgraded_instance_percent = 5
#   pause_time_between_batches              = "PT0S"
# }

 extension {
   name                       = "HealthExtension"
   publisher                  = "Microsoft.ManagedServices"
   type                       = "ApplicationHealthWindows"
   type_handler_version       = "1.0"
   auto_upgrade_minor_version = false

   settings = <<-EOT
   {
     "protocol": "http",
     "port": 80,
     "requestPath": "/"
   }
   EOT
 }

  # required when using rolling upgrade policy and loadbalancer
#  health_probe_id = azurerm_application_gateway.application_gateway.id

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.image_sku          ###  You can select 2016-Datacenter as well.
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 127
#    create_option        = "FromImage"
    storage_account_type = "Standard_LRS"
  }

  data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "terraformnetworkprofile"
    primary = true
    network_security_group_id = azurerm_network_security_group.vmss_nsg.id

    ip_configuration {
      name                                         = "TestIPConfiguration"
      primary                                      = true
      subnet_id                                    = azurerm_subnet.vmss_subnet.id
      application_gateway_backend_address_pool_ids = azurerm_application_gateway.application_gateway.backend_address_pool[*].id
      public_ip_address {
        name = "${var.prefix}-vmss-ip"
        version = "IPv4"  
      }
    }
  }

  # To enable the boot diagnostics
  boot_diagnostics {
    storage_account_uri = ""
  }

  tags = {
    environment = var.env
  }
}

############################################# Use Extension to Execute Powershell Command  ###############################################################

resource "azurerm_virtual_machine_scale_set_extension" "azure_vm_extension" {
  name                 = "${var.prefix}-vm-extension"
#  location            = azurerm_resource_group.mederma.location
#  resource_group_name = azurerm_resource_group.mederma.name
  virtual_machine_scale_set_id   = azurerm_windows_virtual_machine_scale_set.vm_scale_set.id
  publisher            = "Microsoft.Compute"    ### "Microsoft.Azure.Extensions"   ### "Microsoft.Compute/virtualMachineScaleSets"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature Web-Server -IncludeManagementTools"
    }
    SETTINGS

}

############################################## Autoscaling #############################################################

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "VMSS-AutoScaling"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  location            = azurerm_resource_group.azure_resource_group.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.vm_scale_set.id
  enabled             = var.enable_disable_autoscale          ### Default Set to true

  profile {
    name = "VMSS-AutoScale-Profile"

    capacity {
      default = 2
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vm_scale_set.id
        time_grain         = "PT1M"       ### Metrics should be aggregated every 1 minute.
        statistic          = "Average"
        time_window        = "PT5M"       ### Every time autoscale runs, it queries metrics for the past 5 minutes.
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"        ###  Must be between 1 minute and 1 week. The amount of time to wait since the last scaling action.
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vm_scale_set.id
        time_grain         = "PT1M"      ### Metrics should be aggregated every 1 minute
        statistic          = "Average" 
        time_window        = "PT5M"      ### Every time autoscale runs, it queries metrics for the past 5 minutes.
        time_aggregation   = "Average"   
        operator           = "LessThan"
        threshold          = 20
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"       ### Must be between 1 minute and 1 week. The amount of time to wait since the last scaling action.
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = false     ### true
      send_to_subscription_co_administrator = false     ### true
      custom_emails                         = ["shambhugupta9392@gmail.com"]
    }
  }

  tags = {
    environment = var.env
  }

  depends_on = [ azurerm_virtual_machine_scale_set_extension.azure_vm_extension ]
}

