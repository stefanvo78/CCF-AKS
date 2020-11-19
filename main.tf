terraform {
  
  required_version = ">= 0.12"
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.privateaks.kube_admin_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.privateaks.kube_admin_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.privateaks.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.privateaks.kube_admin_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    load_config_file = false
    host                   = azurerm_kubernetes_cluster.privateaks.kube_admin_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.privateaks.kube_admin_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.privateaks.kube_admin_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.privateaks.kube_admin_config.0.cluster_ca_certificate)
    config_path = "ensure-that-we-never-read-kube-config-from-home-dir"
  }
}

provider "azurerm" {
  version = "~>2.5" //outbound_type https://github.com/terraform-providers/terraform-provider-azurerm/blob/v2.5.0/CHANGELOG.md
  features {}
}


data "azurerm_resource_group" "spoke" {
	name     = var.spoke_resource_group_name
}


resource "azurerm_subnet" "aksnet" {
  name                      = var.akssubnet
  resource_group_name       = var.spoke_resource_group_name
  #network_security_group_id = "${azurerm_network_security_group.aksnsg.id}"
  address_prefixes            = var.akssubsnet_adressprefixes
  virtual_network_name      = var.kube_vnet_name

  service_endpoints         = ["Microsoft.AzureCosmosDB", "Microsoft.ContainerRegistry", "Microsoft.EventHub", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_subnet" "appgw" {
  name                      = var.appgwsubnet
  resource_group_name       = var.spoke_resource_group_name
  #network_security_group_id = "${azurerm_network_security_group.aksnsg.id}"
  address_prefixes            = var.appgwsubsnet_adressprefixes
  virtual_network_name      = var.kube_vnet_name

  service_endpoints         = ["Microsoft.AzureCosmosDB", "Microsoft.ContainerRegistry", "Microsoft.EventHub", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_public_ip" "appgw_ip" {
  name                = var.appgw_publicIP
  resource_group_name = var.spoke_resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.appgw_name
  resource_group_name = var.spoke_resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "frontend-port-name"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-config-name"
    public_ip_address_id = azurerm_public_ip.appgw_ip.id
  }

  frontend_ip_configuration {
    name                 = "frontend-private-Ip"
    private_ip_address   = var.appgw_private_ip
    private_ip_address_allocation = "Static"
    subnet_id = azurerm_subnet.appgw.id
  }

  backend_address_pool {
    name = "backend-pool-name"
  }

  backend_http_settings {
    name                  = "http-setting-name"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
    connection_draining {
      enabled = true
      drain_timeout_sec = 30
    }
  }

  probe {
    name                                        = "probe"
    protocol                                    = "http"
    path                                        = "/"
    interval                                    = "30"
    timeout                                     = "30"
    unhealthy_threshold                         = "3"
    pick_host_name_from_backend_http_settings   = true
  }

  http_listener {
    name                           = "listener-name"
    frontend_ip_configuration_name = "frontend-config-name"
    frontend_port_name             = "frontend-port-name"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "listener-name"
    backend_address_pool_name  = "backend-pool-name"
    backend_http_settings_name = "http-setting-name"
  }
}


#data "azurerm_route_table" "routetable" {
#  name                 = var.routetablename
#	resource_group_name  = var.spoke_resource_group_name
#  location                = var.location
#}


#resource "azurerm_subnet_route_table_association" "routetable_subnet" {
#  subnet_id      = azurerm_subnet.aksnet.id
#  route_table_id = azurerm_route_table.routetable.id
#}



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
    vnet_subnet_id =  azurerm_subnet.aksnet.id
  }

  # identity {
  #   type = "SystemAssigned"
  # }

  network_profile {
    docker_bridge_cidr = var.network_docker_bridge_cidr
    dns_service_ip     = var.network_dns_service_ip
    network_plugin     = "azure"
    #outbound_type      = "userDefinedRouting"
    service_cidr       = var.network_service_cidr
  }

  service_principal {
        client_id     = var.client_id
        client_secret = var.client_secret
    }
  
}



#APP Gateway Ingress Config
resource "azurerm_user_assigned_identity" "agicidentity" {
  name = "${var.aksname}-agic-id"
  resource_group_name = var.spoke_resource_group_name
  location            = var.location
}

resource "azurerm_role_assignment" "agicidentityappgw" {
  scope                = azurerm_application_gateway.appgw.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.agicidentity.principal_id
}

resource "azurerm_role_assignment" "agicidentityappgwgroup" {
  scope                = data.azurerm_resource_group.spoke.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.agicidentity.principal_id
}


resource "azurerm_role_assignment" "podidentitykubeletoperator" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_kubernetes_cluster.privateaks.node_resource_group}"
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.privateaks.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.privateaks]
}
# try if can be removed
resource "azurerm_role_assignment" "agicoperator" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_kubernetes_cluster.privateaks.node_resource_group}"
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.agicidentity.principal_id

  depends_on = [azurerm_kubernetes_cluster.privateaks]
}

resource "azurerm_role_assignment" "contolleroperator" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_kubernetes_cluster.privateaks.node_resource_group}"
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.privateaks.identity.0.principal_id

  depends_on = [azurerm_kubernetes_cluster.privateaks]
}







resource "kubernetes_namespace" "dummy-logger-ns" {
  metadata {
    name = "demo"
  }

  depends_on = [azurerm_kubernetes_cluster.privateaks]
}

resource "null_resource" "delay_charts" {
  provisioner "local-exec" {
    command = "sleep 30"
  }

  triggers = {
    "before" = kubernetes_namespace.dummy-logger-ns.id
  }
}

resource "null_resource" "after_charts" {
  depends_on = [null_resource.delay_charts]
}






resource "azurerm_role_assignment" "podidentitycontroller" {
  scope                = data.azurerm_resource_group.spoke.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.privateaks.identity.0.principal_id

  depends_on = [azurerm_kubernetes_cluster.privateaks]
}

resource "azurerm_role_assignment" "podidentitykubelet" {
  scope                = data.azurerm_resource_group.spoke.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.privateaks.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.privateaks]
}

resource "azurerm_role_assignment" "podidentitykubeletcontributor" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_kubernetes_cluster.privateaks.node_resource_group}"
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_kubernetes_cluster.privateaks.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.privateaks]
}

# https://www.terraform.io/docs/providers/helm/release.html
resource "helm_release" "aad-pod-identity" {
  name       = "aad-pod-identity"
  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts" 
  chart      = "aad-pod-identity"
  namespace  = "kube-system"
  force_update = "true"
  timeout = "500"

  depends_on = [azurerm_kubernetes_cluster.privateaks, null_resource.after_charts]
}


# https://www.terraform.io/docs/providers/helm/release.html
resource "helm_release" "ingress-azure" {
  name       = "ingress-azure"
  repository = "https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/" 
  chart      = "ingress-azure"
  namespace  = "kube-system"
  force_update = "true"
  timeout = "500"

  set {
    name  = "appgw.name"
    value = var.appgw_name
  }

  set {
    name  = "appgw.resourceGroup"
    value = var.spoke_resource_group_name
  }

  set {
    name  = "appgw.subscriptionId"
    value = var.subscription_id
  }

  set {
    name  = "appgw.usePrivateIP"
    value = true
  }

  set {
    name  = "appgw.shared"
    value = false
  }

  set {
    name  = "armAuth.type"
    value = "aadPodIdentity"
  }

  set {
    name  = "armAuth.identityClientID"
    value = azurerm_user_assigned_identity.agicidentity.client_id
  }

  set {
    name  = "armAuth.identityResourceID"
    value = azurerm_user_assigned_identity.agicidentity.id
  }

  set {
    name  = "rbac.enabled"
    value = "true"
  }

  set {
    name  = "kubernetes.watchNamespace"
    value = "default"
  }

  depends_on = [azurerm_kubernetes_cluster.privateaks, null_resource.after_charts, helm_release.aad-pod-identity]
}




