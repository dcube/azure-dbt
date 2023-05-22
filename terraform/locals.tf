locals {
  resource_names = {
    resource_group_name                     = "RG-Data-Dwh-${var.environment}-01"
    core_resource_group_name                = "RG-Data-Core-${var.environment}-01"
    key_vault_core_name                     = "kv-data-core-${var.environment}-01"
    service_bus_name                        = "sb-data-${var.spoke_name}-${var.environment}-01"
    service_bus_dbt_run_queue_name          = "dbt-run"
    container_environment_name              = "cae-data-${var.spoke_name}-${var.environment}-01"
    container_app_name                      = "ca-data-${var.spoke_name}-${var.environment}-01"
    container_app_doc_name                  = "ca-data-${var.spoke_name}-${var.environment}-02"
    container_app_managed_identity_name     = "id-data-${var.spoke_name}-${var.environment}-01"
    container_app_managed_identity_name_doc = "id-data-${var.spoke_name}-${var.environment}-02"
    container_registry_name                 = "xxx"
    container_registry_resource_group       = "RG-Core-01"
    orchestrate_function_name               = "func-data-core-${var.environment}-01"
    monitoring = {
      log_analytics_name       = "log-data-core-${var.environment}-01"
      storage_diagnostics_name = "stdatacore${var.environment}02"
    }
  }
}