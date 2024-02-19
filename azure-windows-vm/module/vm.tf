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
    destination_port_range     = "3389"
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

resource "azurerm_windows_virtual_machine" "azure_windows_vm" {
  name                  = "${var.prefix}-windows-vm"
  location              = azurerm_resource_group.mederma.location
  resource_group_name   = azurerm_resource_group.mederma.name
  network_interface_ids = [azurerm_network_interface.vnet_interface.id]
  size                  = var.vm_size
  zone                  = var.availability_zone[0]
  
  computer_name  = var.computer_name
  admin_username = var.admin_username
  admin_password = var.admin_password
# custom_data    = filebase64("custom_data.ps1")

  # Uncomment this line to delete the OS disk automatically when deleting the VM
#  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
#  delete_data_disks_on_termination = true

  #### Boot Diagnostics is Enable with managed storage account ########
  boot_diagnostics {
    storage_account_uri = ""
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.image_sku
    version   = "latest"
  }
  os_disk {
    name                 = "${var.prefix}-osdisk"
    caching              = "ReadWrite"
#    create_option        = "FromImage"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size_gb
  }
  tags = {
    environment = var.env
  }
}

resource "azurerm_managed_disk" "data_disk" {
  name                 = "${var.prefix}-datadisk"
  location             = azurerm_resource_group.mederma.location
  resource_group_name  = azurerm_resource_group.mederma.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  zone                 = var.availability_zone[0]
  disk_size_gb         = var.extra_disk_size_gb
  
  depends_on           = [azurerm_windows_virtual_machine.azure_windows_vm]
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.azure_windows_vm.id
  lun                = 0
  caching            = "ReadWrite"

  depends_on         = [azurerm_windows_virtual_machine.azure_windows_vm, azurerm_managed_disk.data_disk]
}

resource "azurerm_virtual_machine_extension" "azure_vm_extension" {
  name                 = "${var.prefix}-vm-extension"
#  location            = azurerm_resource_group.mederma.location
#  resource_group_name = azurerm_resource_group.mederma.name
  virtual_machine_id   = azurerm_windows_virtual_machine.azure_windows_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe get-disk; Initialize-Disk -Number 2 -PartitionStyle MBR; New-Partition -DiskNumber 2 -UseMaximumSize -IsActive -DriveLetter F; Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel myDrive; get-volume"
    }
    SETTINGS

   depends_on = [azurerm_virtual_machine_data_disk_attachment.data_disk_attachment]
}
