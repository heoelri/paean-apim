# creates a new private dns zone called paean.local
resource "azurerm_private_dns_zone" "stamp" {
  name                = "paean.local"
  resource_group_name = azurerm_resource_group.stamp.name
}

# links the private dns zone to the virtual network for auto-registration
resource "azurerm_private_dns_zone_virtual_network_link" "stamp" {
  name                  = "dnsregistration"
  resource_group_name   = azurerm_resource_group.stamp.name
  private_dns_zone_name = azurerm_private_dns_zone.stamp.name
  virtual_network_id    = azurerm_virtual_network.stamp.id
}

# a record / dns entry for portal.apollo.local
resource "azurerm_private_dns_a_record" "portal" {
  name                = "portal"
  zone_name           = azurerm_private_dns_zone.stamp.name
  resource_group_name = azurerm_resource_group.stamp.name
  ttl                 = 300
  records             = [azurerm_api_management.stamp.private_ip_addresses[0]]
}

# a record / dns entry for api.apollo.local
resource "azurerm_private_dns_a_record" "api" {
  name                = "api"
  zone_name           = azurerm_private_dns_zone.stamp.name
  resource_group_name = azurerm_resource_group.stamp.name
  ttl                 = 300
  records             = [azurerm_api_management.stamp.private_ip_addresses[0]]
}