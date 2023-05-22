resource "azurerm_key_vault_secret" "service_bus" {
  name         = "dwh-namespace"
  value        = azurerm_servicebus_namespace.this.name
  key_vault_id = data.azurerm_key_vault.core.id
}

resource "azurerm_key_vault_secret" "queue" {
  name         = "dwh-queue"
  value        = azurerm_servicebus_queue.queue.name
  key_vault_id = data.azurerm_key_vault.core.id
}