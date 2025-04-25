terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.43.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
  }
}

# provider "kubernetes" {
#   host                   = try(azurerm_kubernetes_cluster.aks.kube_config[0].host, null)
#   client_certificate     = try(base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate), null)
#   client_key             = try(base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key), null)
#   cluster_ca_certificate = try(base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate), null)

#   # Establece esta opción para permitir configuración parcial durante la inicialización
#   ignore_absent_fields = true
# }

# Configuración de AAD
provider "azuread" {
}