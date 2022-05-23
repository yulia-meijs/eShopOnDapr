resource "azurerm_mssql_server" "server" {
  name                         = var.sql_server_name == null ? "${var.prefix}-sqlsrv" : var.sql_server_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  version                      = var.sql_version
  tags  = var.tags
  identity {
    type = "SystemAssigned"
  }
  azuread_administrator {
    login_username = "sql-admin"
    object_id = "50e73168-0654-41b3-ba63-cf08fa5b3e33"
    azuread_authentication_only = true
    }
}

//allow the kube subnet
resource "azurerm_mssql_virtual_network_rule" "main" {
  name                = "sqlserver-vnet-rule"
  subnet_id           = var.vnet_rule_subnet_id
  server_id           = azurerm_mssql_server.server.id
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name                = "allow-azure-services"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
  server_id           = azurerm_mssql_server.server.id
}

resource "azurerm_mssql_firewall_rule" "allow_extra" {
  for_each = { for rule in var.sql_firewall_rules : rule.name => rule }
  name = each.key
  server_id = azurerm_mssql_server.server.id
  start_ip_address = each.value.start_ip_address
  end_ip_address = each.value.end_ip_address
}

resource "azurerm_mssql_database" "database" {
  for_each = { for db in var.databases : db.name => db }
  name                = each.key
  sku_name = each.value.sku_name
  license_type = each.value.license_type
  zone_redundant = each.value.zone_redundant
  server_id           = azurerm_mssql_server.server.id
}