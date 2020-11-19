terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  version = "~>2.5" //outbound_type https://github.com/terraform-providers/terraform-provider-azurerm/blob/v2.5.0/CHANGELOG.md
  features {}
}


data "azurerm_resource_group" "spoke" {
	name     = var.spoke_resource_group_name
}

#fetch existing subnet 
data "azurerm_subnet" "aks" {
	name                 = var.akssubnet
	virtual_network_name = var.kube_vnet_name
	resource_group_name  = var.spoke_resource_group_name
}

resource "azurerm_kubernetes_cluster" "privateaks" {
  name                    = var.aksname
  location                = var.location
  kubernetes_version      = var.aksversion
  resource_group_name     = var.spoke_resource_group_name
  dns_prefix              = var.dns_prefix
  private_cluster_enabled = true

  default_node_pool {
    name           = "default"
    node_count     = var.nodepool_nodes_count
    vm_size        = var.nodepool_vm_size
    vnet_subnet_id =  data.azurerm_subnet.aks.id
  }

  # identity {
  #   type = "SystemAssigned"
  # }

  network_profile {
    docker_bridge_cidr = var.network_docker_bridge_cidr
    dns_service_ip     = var.network_dns_service_ip
    network_plugin     = "azure"
    outbound_type      = "userDefinedRouting"
    service_cidr       = var.network_service_cidr
  }

  service_principal {
        client_id     = var.client_id
        client_secret = var.client_secret
    }
  
}






