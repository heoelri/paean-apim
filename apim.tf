resource "azurerm_api_management" "stamp" {
  name                = "${local.prefix}-apim"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  publisher_name      = "My Company"
  publisher_email     = "company@terraform.io"

  sku_name = "Premium_1"

  identity {
    type = "SystemAssigned"
  }

  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim.id
  }
}

# creating a new custom domain for api management
resource "azurerm_api_management_custom_domain" "apim" {
  api_management_id = azurerm_api_management.stamp.id

  gateway {
    host_name    = "${azurerm_private_dns_a_record.api.name}.${azurerm_private_dns_zone.stamp.name}"
    key_vault_id = azurerm_key_vault_certificate.selfsigned.secret_id
  }

  developer_portal {
    host_name    = "${azurerm_private_dns_a_record.portal.name}.${azurerm_private_dns_zone.stamp.name}"
    key_vault_id = azurerm_key_vault_certificate.selfsigned.secret_id
  }

  depends_on = [
    azurerm_key_vault_access_policy.apim_msi # APIM MSI needs access to KeyVault first
  ]
}

# Network security rule for APIM
resource "azurerm_network_security_rule" "apim" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_apim_management"
  network_security_group_name = azurerm_network_security_group.apim.name
  resource_group_name         = azurerm_resource_group.stamp.name

  priority                    = "100"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "3443"
  source_address_prefix      = "ApiManagement"
  destination_address_prefix = "VirtualNetwork"
}

# Create Echo API
resource "azurerm_api_management_api" "echo" {
  name                = "echo-api"
  resource_group_name = azurerm_resource_group.stamp.name
  api_management_name = azurerm_api_management.stamp.name
  revision            = "1"
  display_name        = "Echo API"
  path                = "echo"
  protocols           = ["https"]

  service_url = "http://postman-echo.com/get"
}

resource "azurerm_api_management_api_operation" "echo" {
  operation_id        = "echo-api"
  api_name            = azurerm_api_management_api.echo.name
  api_management_name = azurerm_api_management_api.echo.api_management_name
  resource_group_name = azurerm_api_management_api.echo.resource_group_name
  display_name        = "Echo API"
  method              = "GET"
  url_template        = "/echo"
  #description         = "This can only be done by the logged in user."

  #response {
  #  status_code = 200
  #}
}