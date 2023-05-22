#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace
resource "azurerm_servicebus_namespace" "this" {
  name                = local.resource_names.service_bus_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  sku                 = var.service_bus_sku_name

  tags = merge(data.azurerm_resource_group.this.tags, {
    Role = "Bus used for asynchronous micro services"
  })
}

resource "azurerm_servicebus_queue" "queue" {
  name         = local.resource_names.service_bus_dbt_run_queue_name
  namespace_id = azurerm_servicebus_namespace.this.id
}

# Container app must be able to receive bus message
resource "azurerm_role_assignment" "service_bus_receiver_assignment" {
  scope                = azurerm_servicebus_namespace.this.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.aci_identity.principal_id
}

# Core Function app must be able to send bus message
resource "azurerm_role_assignment" "service_bus_sender_assignment" {
  scope                = azurerm_servicebus_namespace.this.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = data.azurerm_linux_function_app.orchestrate.identity[0].principal_id
}