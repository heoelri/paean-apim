resource "azurerm_key_vault" "stamp" {
  name                        = "${local.prefix}-kv"
  location                    = azurerm_resource_group.stamp.location
  resource_group_name         = azurerm_resource_group.stamp.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "SetIssuers",
      "Update",
    ]

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "Set",
      "List",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_key_vault_certificate" "selfsigned" {
  name         = "self-signed-cert"
  key_vault_id = azurerm_key_vault.stamp.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["api.paean.local", "portal.paean.local"]
      }

      subject            = "CN=paean.local"
      validity_in_months = 12
    }
  }
}

# Azure KeyVault access policy to grant APIM access to secrets
resource "azurerm_key_vault_access_policy" "apim_msi" {
  key_vault_id = azurerm_key_vault.stamp.id
  tenant_id    = azurerm_api_management.stamp.identity[0].tenant_id
  object_id    = azurerm_api_management.stamp.identity[0].principal_id

  certificate_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
  ]
}

# Generate a random password used to login to the client vm
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"

  keepers = {
    value = azurerm_resource_group.stamp.name # generate once 
  }
}

# Store adminpassword for client vm in azure key vault
resource "azurerm_key_vault_secret" "client_adminpassword" {
  name         = "client-adminpassword"
  value        = random_password.password.result
  key_vault_id = azurerm_key_vault.stamp.id
}