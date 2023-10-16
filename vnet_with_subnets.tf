# Task : 
# 1)	Create a virtual network using terraform and create a single CIDR block in it 172.33.0.0/16
# 2)	Create 3 Subnets, one each for DMZ, Data and Compute.

#Provider
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "myrg" {
  name     = "myResourceGroup"
  location = "East Asia"
}

# Vitural network
resource "azurerm_virtual_network" "myvnet" {
  name                = "myvnet"
  address_space       = ["172.33.0.0/16"]
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
}

# Output the Vnet
output "vnet_id" {
  value = azurerm_virtual_network.myvnet.id
}

# Subnet DMZ
resource "azurerm_subnet" "dmz" {
  name                 = "dmz"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["172.33.0.0/18"] # dmz with a /18 prefix
  depends_on           = [azurerm_virtual_network.myvnet]
}

resource "azurerm_subnet" "data" {
  name                 = "data"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["172.33.64.0/18"] # data with a /18 prefix
  depends_on           = [azurerm_virtual_network.myvnet]
}

resource "azurerm_subnet" "compute" {
  name                 = "compute"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["172.33.128.0/18"] # compute with a /18 prefix
  depends_on           = [azurerm_virtual_network.myvnet]
}
