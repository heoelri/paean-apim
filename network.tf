# Azure Virtual Network
resource "azurerm_virtual_network" "stamp" {
  name                = "${local.prefix}-vnet"
  resource_group_name = azurerm_resource_group.stamp.name
  location            = azurerm_resource_group.stamp.location
  address_space       = ["10.10.0.0/16"]
}

# Network subnet for API Management
resource "azurerm_subnet" "apim" {
  name                 = "apim"
  resource_group_name  = azurerm_resource_group.stamp.name
  virtual_network_name = azurerm_virtual_network.stamp.name
  address_prefixes     = ["10.10.1.0/24"]
}

# Network Security Group for APIM
resource "azurerm_network_security_group" "apim" {
  name                = "${local.prefix}-apim-nsg"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
}

# Associate APIM NSG with APIM subnet
resource "azurerm_subnet_network_security_group_association" "apim" {
  subnet_id                 = azurerm_subnet.apim.id
  network_security_group_id = azurerm_network_security_group.apim.id
}

# Network subnet for client
resource "azurerm_subnet" "client" {
  name                 = "client"
  resource_group_name  = azurerm_resource_group.stamp.name
  virtual_network_name = azurerm_virtual_network.stamp.name
  address_prefixes     = ["10.10.2.0/24"]
}

# Network Security Group for Client subnet
resource "azurerm_network_security_group" "client" {
  name                = "${local.prefix}-client-nsg"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
}

# Associate Client NSG with Client subnet
resource "azurerm_subnet_network_security_group_association" "client" {
  subnet_id                 = azurerm_subnet.client.id
  network_security_group_id = azurerm_network_security_group.client.id
}

# Network subnet for Azure Bastion host
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.stamp.name
  virtual_network_name = azurerm_virtual_network.stamp.name
  address_prefixes     = ["10.10.3.0/24"]
}