output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "aks_host" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.host
  sensitive = true
}

output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}

output "acr_login_server" {
  value = var.create_acr ? azurerm_container_registry.acr[0].login_server : null
}

# output "github_actions_service_principal" {
#   value = {
#     client_id     = azuread_application.github_actions.application_id
#     client_secret = azuread_service_principal_password.github_actions.value
#   }
#   sensitive = true
# }

# output "github_actions_azure_credentials_json" {
#   value = jsonencode({
#     clientId       = azuread_application.github_actions.application_id
#     clientSecret   = azuread_service_principal_password.github_actions.value
#     subscriptionId = data.azurerm_subscription.current.subscription_id
#     tenantId       = data.azurerm_subscription.current.tenant_id
#   })
#   sensitive = true
# }

# Data source para obtener el ID de la suscripción actual
# data "azurerm_subscription" "current" {}