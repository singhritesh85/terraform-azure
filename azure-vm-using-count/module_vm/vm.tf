resource "azurerm_public_ip" "public_ip" {
  name                = "${var.vm_name}-ip"
  resource_group_name = var.resource_group_name      #azurerm_resource_group.mederma.name
  location            = var.location                   #azurerm_resource_group.mederma.location
  allocation_method   = var.static_dynamic[0]
  sku                 = "Standard"   ### Basic, For Availability Zone to be Enabled the SKU of Public IP must be Standard
  zones               = var.availability_zone
  
#  depends_on          = [azurerm_virtual_network.vnet, azurerm_subnet.vnet_subnet]
}

resource "azurerm_network_interface" "vnet_interface" {
  name                = "${var.vm_name}-nic"
  location            = var.location              #  azurerm_resource_group.mederma.location
  resource_group_name = var.resource_group_name      #azurerm_resource_group.mederma.name

  ip_configuration {
    name                          = "${var.prefix}-ip-configuration"
    subnet_id                     =  var.subnet_id        # azurerm_subnet.vnet_subnet.id
    private_ip_address_allocation = var.static_dynamic[1]
    public_ip_address_id = element(azurerm_public_ip.public_ip.*.id, var.val)
  }
  depends_on          = [azurerm_public_ip.public_ip]
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [azurerm_network_interface.vnet_interface]

  destroy_duration = "60s"
}

#resource "azurerm_network_security_group" "nsg" {
#  name                = "ssh_nsg"
#  location            = var.location                  # azurerm_resource_group.mederma.location
#  resource_group_name = var.resource_group_name      #azurerm_resource_group.mederma.name

#  security_rule {
#    name                       = "allow_ssh_sg"
#    priority                   = 100
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "Tcp"
#    source_port_range          = "*"
#    destination_port_range     = "22"
#    source_address_prefix      = "*"
#    destination_address_prefix = "*"
#  }

######  provisioner "local-exec" {
######     when    = destroy
######     command = "sleep 75"
######  } 

#  depends_on = [time_sleep.wait_150_seconds]
######  depends_on = [azurerm_network_interface.vnet_interface, azurerm_public_ip.public_ip]
#}

#resource "azurerm_network_interface_security_group_association" "association" {
#  network_interface_id      = azurerm_network_interface.vnet_interface.id
#  network_security_group_id = azurerm_network_security_group.nsg.id
#  depends_on = [azurerm_network_security_group.nsg, azurerm_network_interface.vnet_interface, azurerm_public_ip.public_ip]
#}

resource "azurerm_virtual_machine" "azure_vm" {
  
  name                  = var.vm_name
  location              = var.location               # azurerm_resource_group.mederma.location
  resource_group_name   = var.resource_group_name             #azurerm_resource_group.mederma.name
  network_interface_ids = [element(azurerm_network_interface.vnet_interface.*.id, var.val)]
  vm_size               = var.vm_size
  zones                 = var.availability_zone

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  #### Boot Diagnostics is Enable with managed storage account ########
  boot_diagnostics {
    enabled = true
    storage_uri = ""
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }
  storage_os_disk {
    name              = "osdisk-${var.vm_name}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = var.disk_size_gb
  }
  os_profile {
    computer_name  = var.vm_name
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data    = filebase64("custom_data.sh")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = var.env  
  }
  depends_on = [time_sleep.wait_60_seconds, azurerm_network_interface.vnet_interface, azurerm_public_ip.public_ip]
}
