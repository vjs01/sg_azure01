output "azurerm_postgresql_flexible_server" {
    value = azurerm_postgresql_flexible_server.default.name
}

output "postgresql_flexible_server_database_name" {
    value = azurerm_postgresql_flexible_server_database.default.name
}
output "postgresql_flexible_server_admin" {
    value = "adminTerraform"
}
output "postgresql_flexible_server_password" {
    value = random_password.password.result
    sensitive = true
}