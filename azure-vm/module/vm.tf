resource "azurerm_resource_group" "mederma" {
  name     = "${var.prefix}-resource-group"
  location = var.location
  
  tags = {
    environment = var.env
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-network"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.mederma.location
  resource_group_name = azurerm_resource_group.mederma.name

  tags = {
    environment = var.env
  }
}

resource "azurerm_subnet" "vnet_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.mederma.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "azure_nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.mederma.location
  resource_group_name = azurerm_resource_group.mederma.name

  security_rule {
    name                       = "azure_nsg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.env
  }
}

######## NSG has been attached to subnet, However it is also possible to attach NSG to Network Interface(NIC) ###########

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_attachent" {
  subnet_id                 = azurerm_subnet.vnet_subnet.id
  network_security_group_id = azurerm_network_security_group.azure_nsg.id
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-ip"
  resource_group_name = azurerm_resource_group.mederma.name
  location            = azurerm_resource_group.mederma.location
  allocation_method   = var.static_dynamic[0]

  sku = "Standard"   ### Basic, For Availability Zone to be Enabled the SKU of Public IP must be Standard  
  zones = var.availability_zone

  tags = {
    environment = var.env
  }
}

resource "azurerm_network_interface" "vnet_interface" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.mederma.location
  resource_group_name = azurerm_resource_group.mederma.name

  ip_configuration {
    name                          = "${var.prefix}-ip-configuration"
    subnet_id                     = azurerm_subnet.vnet_subnet.id
    private_ip_address_allocation = var.static_dynamic[1]
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
  
  tags = {
    environment = var.env
  }
}

resource "azurerm_virtual_machine" "azure_vm" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.mederma.location
  resource_group_name   = azurerm_resource_group.mederma.name
  network_interface_ids = [azurerm_network_interface.vnet_interface.id]
  vm_size               = var.vm_size
  zones                 = var.availability_zone

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

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
    name              = "${var.prefix}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = var.disk_size_gb
  }
  os_profile {
    computer_name  = var.computer_name
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data    = filebase64("custom_data.sh") 
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  storage_data_disk {
    name              = "${var.prefix}-datadisk"
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = var.extra_disk_size_gb
    lun               = 0
    managed_disk_type = "Standard_LRS"
  }
  tags = {
    environment = var.env
  }
}
