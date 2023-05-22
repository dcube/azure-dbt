data "azurerm_resource_group" "this" {
  name = local.resource_names.resource_group_name
}

data "azurerm_resource_group" "core" {
  name = local.resource_names.core_resource_group_name
}

data "azurerm_log_analytics_workspace" "core" {
  name                = local.resource_names.monitoring.log_analytics_name
  resource_group_name = data.azurerm_resource_group.core.name
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/container_registry
data "azurerm_container_registry" "this" {
  provider = azurerm.Infrastructure

  name                = local.resource_names.container_registry_name
  resource_group_name = local.resource_names.container_registry_resource_group
}

data "azurerm_key_vault" "core" {
  name                = local.resource_names.key_vault_core_name
  resource_group_name = data.azurerm_resource_group.core.name
}

data "azurerm_linux_function_app" "orchestrate" {
  name                = local.resource_names.orchestrate_function_name
  resource_group_name = data.azurerm_resource_group.core.name
}

data "azurerm_function_app_host_keys" "orchestrate" {
  name                = local.resource_names.orchestrate_function_name
  resource_group_name = data.azurerm_resource_group.core.name
}