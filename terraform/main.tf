resource "random_id" "rg_name" {
  byte_length = 8
}

resource "random_password" "password" {
  length = 8
}

resource "random_pet" "rg-name" {
  prefix = var.name_prefix
}

resource "azurerm_resource_group" "default" {
  name     = random_pet.rg-name.id
  location = var.location
}

resource "azurerm_virtual_network" "default" {
  name                = "${var.name_prefix}-vnet"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_network_security_group" "default" {
  name                = "${var.name_prefix}-nsg"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "default" {
  name                 = "${var.name_prefix}-subnet"
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = azurerm_resource_group.default.name
  address_prefixes     = ["10.10.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

/*  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }*/
}

resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.default.id
}

/*resource "azurerm_private_dns_zone" "default" {
  name                = "${var.name_prefix}-pdz.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.default.name

  depends_on = [azurerm_subnet_network_security_group_association.default]
}

resource "azurerm_private_dns_zone_virtual_network_link" "default" {
  name                  = "${var.name_prefix}-pdzvnetlink.com"
  private_dns_zone_name = azurerm_private_dns_zone.default.name
  virtual_network_id    = azurerm_virtual_network.default.id
  resource_group_name   = azurerm_resource_group.default.name
}*/

resource "azurerm_postgresql_flexible_server" "default" {
  name                   = "${var.name_prefix}-svr-${random_id.rg_name.hex}"
  resource_group_name    = azurerm_resource_group.default.name
  location               = azurerm_resource_group.default.location
 
  version                = "13"
  //delegated_subnet_id    = azurerm_subnet.default.id
  //private_dns_zone_id    = azurerm_private_dns_zone.default.id
  //public_azure_access_enabled = true
  
  administrator_login    = "adminTerraform"
  administrator_password = random_password.password.result
 
  zone                   = "1"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"
  backup_retention_days  = 7

  //ssl_enforcement_enabled      = true
  
 //depends_on = [azurerm_private_dns_zone_virtual_network_link.default]
}

resource "azurerm_postgresql_flexible_server_database" "default" {
  name      = "${var.name_prefix}-db"
  server_id = azurerm_postgresql_flexible_server.default.id
  collation = "en_US.UTF8"
  charset   = "UTF8"
}

/*resource "azurerm_postgresql_flexible_server_firewall_rule" "default" {
  name                = "rule1"
  //resource_group_name = azurerm_resource_group.default.name
  server_id       = azurerm_postgresql_flexible_server.default.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "default2" {
  name                = "rule2"
  //resource_group_name = azurerm_resource_group.default.name
  server_id       = azurerm_postgresql_flexible_server.default.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
} */

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure" {
 // count = var.public_network_access_enabled ? 1 : 0

  name             = "allow-access-from-azure-services"
  server_id        = azurerm_postgresql_flexible_server.default.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "all" {
//  count = var.public_network_access_enabled && var.firewall_allow_all_ips ? 1 : 0

  name             = "allow-all-ips"
  server_id        = azurerm_postgresql_flexible_server.default.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}