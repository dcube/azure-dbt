# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment
resource "azurerm_container_app_environment" "container_environment" {
  name                       = local.resource_names.container_environment_name
  location                   = data.azurerm_resource_group.this.location
  resource_group_name        = data.azurerm_resource_group.this.name
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.core.id

  tags = merge(data.azurerm_resource_group.this.tags, {
    Role = "Container Environment pour DBT"
  })
}

# Add managed identity to assign role to Container App before it is created. If we use Container App System Identity, the first run fails because roles take some time to apply
#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity
resource "azurerm_user_assigned_identity" "aci_identity" {
  name                = local.resource_names.container_app_managed_identity_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  tags = merge(data.azurerm_resource_group.this.tags, { Role = "Identité de la container app" })
}

resource "azurerm_user_assigned_identity" "aci_identity_doc" {
  name                = local.resource_names.container_app_managed_identity_name_doc
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  tags = merge(data.azurerm_resource_group.this.tags, { Role = "Identité de la container app" })
}

# Container app must be able to pull image
resource "azurerm_role_assignment" "container_app_pull_assignment" {
  scope                = data.azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aci_identity.principal_id
}

resource "azurerm_role_assignment" "container_app_pull_assignment_doc" {
  scope                = data.azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aci_identity_doc.principal_id
}

#https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/azapi_resource
resource "azapi_resource" "container_app" {
  name      = local.resource_names.container_app_name
  location  = data.azurerm_resource_group.this.location
  parent_id = data.azurerm_resource_group.this.id
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aci_identity.id]
  }
  type = "Microsoft.App/containerApps@2022-03-01"

  body = jsonencode({
    properties : {
      managedEnvironmentId = azurerm_container_app_environment.container_environment.id
      configuration = {
        secrets = [
          {
            name  = "function-key"
            value = data.azurerm_function_app_host_keys.orchestrate.default_function_key
          },
          {
            name  = "service-bus-connection-string"
            value = azurerm_servicebus_namespace.this.default_primary_connection_string
          }
        ]
        ingress = null
        registries = [
          {
            server   = data.azurerm_container_registry.this.login_server
            identity = azurerm_user_assigned_identity.aci_identity.id
        }]
      }
      template = {
        containers = [{
          image = "${data.azurerm_container_registry.this.login_server}/${var.container_repository}:${var.container_image_tag}"
          name  = "dbt-instance"
          resources = {
            cpu    = var.container_cpu
            memory = var.container_memory
          }
          env = [
            {
              name  = "SB_NAMESPACE"
              value = azurerm_servicebus_namespace.this.name
            },
            {
              name  = "SB_QUEUE_NAME"
              value = local.resource_names.service_bus_dbt_run_queue_name
            },
            {
              name  = "FUNCTION_URL"
              value = data.azurerm_linux_function_app.orchestrate.default_hostname
            },
            {
              name  = "FUNCTION_KEY"
              secretRef = "function-key"
            },
            {
              name  = "AZURE_CLIENT_ID"
              value = azurerm_user_assigned_identity.aci_identity.client_id
            }
          ]
        }]
        scale = {
          minReplicas = 0
          maxReplicas = 5
          rules = [{
            name = "queue-based-autoscaling"
            custom = {
              type = "azure-servicebus"
              metadata = {
                queueName    = local.resource_names.service_bus_dbt_run_queue_name
                messageCount = "1"
                namespace    = azurerm_servicebus_namespace.this.name
              }
              auth = [{
                secretRef        = "service-bus-connection-string"
                triggerParameter = "connection"
              }]
            }
          }]
        }
      }
    }
  })

  tags = merge(data.azurerm_resource_group.this.tags, {
    Role = "Container app pour DBT"
  })

  depends_on = [
    azurerm_role_assignment.container_app_pull_assignment
  ]
}

resource "azapi_resource" "container_app_docs" {
  name      = local.resource_names.container_app_doc_name
  location  = data.azurerm_resource_group.this.location
  parent_id = data.azurerm_resource_group.this.id
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aci_identity_doc.id]
  }
  type = "Microsoft.App/containerApps@2022-03-01"

  body = jsonencode({
    properties : {
      managedEnvironmentId = azurerm_container_app_environment.container_environment.id
      configuration = {
        secrets = []
        ingress = {
          external      = true
          targetPort    = 8080
          allowInsecure = false
          # ipSecurityRestrictions = {
          #   name = ""
          #   ipAddressRange = ""
          #   action = "Allow"
          # }
        }
        registries = [
          {
            server   = data.azurerm_container_registry.this.login_server
            identity = azurerm_user_assigned_identity.aci_identity_doc.id
        }]
      }
      template = {
        containers = [{
          image = "${data.azurerm_container_registry.this.login_server}/${var.container_doc_repository}:${var.container_image_tag}"
          name  = "dbt-instance"
          resources = {
            cpu    = var.container_cpu
            memory = var.container_memory
          }
          env = []
        }]
        scale = {
          minReplicas = 0
          maxReplicas = 1
          rules = [{
            name = "httpscalingrule"
            custom = {
              type = "http"
              metadata = {
                "concurrentRequests" : "100"
              }
            }
          }]
        }
      }
    }
  })

  tags = merge(data.azurerm_resource_group.this.tags, {
    Role = "Container app pour la doc DBT"
  })

  depends_on = [
    azurerm_role_assignment.container_app_pull_assignment_doc
  ]
}