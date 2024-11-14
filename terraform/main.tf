provider "azurerm" {
  features {}
  subscription_id = var.appId
  client_id       = var.displayName
  client_secret   = var.password
  tenant_id       = var.tenant
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-k8s-demo"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-demo"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "production"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "additional_nodes" {
  name                  = "extra-nodes"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  node_count            = 2
  vm_size               = "Standard_B1s"
}

# Outputs for later use
output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.raw_kube_config
}
