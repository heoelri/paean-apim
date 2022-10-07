resource "azurerm_public_ip" "bastion" {
  name                = "${local.prefix}-bastion-pip"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "stamp" {
  name                = "${local.prefix}-bastion"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

# Network Security Group for Azure Bastion Host
resource "azurerm_network_security_group" "bastion" {
  name                = "${local.prefix}-bastion-nsg"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
}

# Bastion Inbound Rules
resource "azurerm_network_security_rule" "AllowHttpsInbound" {
  name                        = "AllowHttpsInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.bastion.name
}
resource "azurerm_network_security_rule" "AllowGatewayManagerInbound" {
  name                        = "AllowGatewayManagerInbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.bastion.name
}
resource "azurerm_network_security_rule" "AllowAzureLoadBalancerInbound" {
  name                        = "AllowAzureLoadBalancerInbound"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.bastion.name
}
resource "azurerm_network_security_rule" "AllowBastionHostCommunication" {
  name                        = "AllowBastionHostCommunication"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_ranges          = ["5701", "8080"]
  destination_port_ranges     = ["5701", "8080"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

# Bastion Outbound Rules
resource "azurerm_network_security_rule" "AllowSshRdpOutbound" {
  name                        = "AllowSshRdpOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_ranges          = ["22", "3389"]
  destination_port_ranges     = ["22", "3389"]
  source_address_prefix       = "*"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.bastion.name
}
resource "azurerm_network_security_rule" "AllowAzureCloudOutbound" {
  name                        = "AllowAzureCloudOutbound"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "443"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureCloud"
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.bastion.name
}
resource "azurerm_network_security_rule" "AllowBastionCommunication" {
  name                        = "AllowBastionCommunication"
  priority                    = 120
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_ranges          = ["5701", "8080"]
  destination_port_ranges     = ["5701", "8080"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.bastion.name
}
resource "azurerm_network_security_rule" "AllowGetSessionInformation" {
  name                        = "AllowGetSessionInformation"
  priority                    = 130
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "80"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
  depends_on = [
    azurerm_network_security_rule.AllowHttpsInbound,
    azurerm_network_security_rule.AllowGatewayManagerInbound,
    azurerm_network_security_rule.AllowAzureLoadBalancerInbound,
    azurerm_network_security_rule.AllowBastionHostCommunication,
    azurerm_network_security_rule.AllowSshRdpOutbound,
    azurerm_network_security_rule.AllowAzureCloudOutbound,
    azurerm_network_security_rule.AllowBastionCommunication,
    azurerm_network_security_rule.AllowGetSessionInformation
  ]
}