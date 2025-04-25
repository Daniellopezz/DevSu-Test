provider "azurerm" {
  features {}
  skip_provider_registration = true
}

locals {
  location        = var.location
  resource_prefix = var.resource_prefix
  environment     = var.environment
  tags = {
    Environment = var.environment
    Project     = "devsu-test"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_prefix}-rg"
  location = local.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.resource_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "${local.resource_prefix}-aks-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.resource_prefix}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${local.resource_prefix}-aks"
  kubernetes_version  = "1.30.11"
  tags                = local.tags

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.node_size
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id
    os_disk_size_gb     = 30
    enable_auto_scaling = true
    min_count           = var.node_count_min
    max_count           = var.node_count_max
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.aks_identity.id
    ]
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  role_based_access_control_enabled = true

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  depends_on = [
    azurerm_user_assigned_identity.aks_identity,
    azurerm_log_analytics_workspace.workspace
  ]
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "${local.resource_prefix}-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_public_ip" "appgw_pip" {
  name                = "${local.resource_prefix}-appgw-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = local.tags
  allocation_method   = "Static"

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${local.resource_prefix}-appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = "default-backend-pool"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "default-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "default-backend-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 1
  }

  depends_on = [
    azurerm_public_ip.appgw_pip,
    azurerm_subnet.appgw_subnet
  ]
}

resource "azurerm_container_registry" "acr" {
  count               = var.create_acr ? 1 : 0
  name                = replace("${local.resource_prefix}acr", "-", "")
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = local.tags

  depends_on = [azurerm_resource_group.rg]
}