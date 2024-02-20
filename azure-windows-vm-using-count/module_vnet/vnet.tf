resource "azurerm_resource_group" "mederma" {
  name     = "${var.prefix}-resource-group"
  location = var.location
  
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-network"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.mederma.location
  resource_group_name = azurerm_resource_group.mederma.name

}

resource "azurerm_subnet" "vnet_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.mederma.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]

}

resource "azurerm_network_security_group" "nsg" {
  name                = "RDP_NSG"
  location            = azurerm_resource_group.mederma.location            ####  location            = var.location
  resource_group_name = azurerm_resource_group.mederma.name                ####  resource_group_name = var.resource_group_name 

  security_rule {
    name                       = "allow_rdp_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


}

############# NSG has been created and attached to Subnet However It is also possible to create and attach a NSG at Network Interface (NIC) ###############

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.vnet_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


