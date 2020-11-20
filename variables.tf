variable "location" {
  description = "The resource group location"
  default     = "West Europe"
}

variable "aksversion" {
  description = "AKS Version"
  default     = "1.18.8"
}

variable "aksname" {
  description = "AKS Version"
  default     = "private-aks"
}




variable "kube_vnet_name" {
  description = "AKS VNET name"
  default     = "VNET-JDIK-DEV"
}


variable "routetablename" {
  description = "Route Table Name"
  default     = "RT-JDIK-DEV"
}


variable "akssubsnet_adressprefixes" {
  description = "IP Range of Non Routable AKS Subnet"
  type    = list(string)
  default = ["172.16.0.0/16"]
}

variable "akssubnet" {
  description = "AKS Subnet name"
  default     = "subnet-JDIK-AKS"
}

variable "appgwsubsnet_adressprefixes" {
  description = "IP Range for App Gateway Subnet"
  type    = list(string)
  default = ["10.29.30.128/28"]
}

variable "appgw_private_ip" {
  description = "Private IP  for App Gateway"
  default = "10.29.30.132"
}


variable "appgw_publicIP" {
  description = "Gateway Public IP name"
  default     = "AppGW_PublicIP"
}

variable "appgw_name" {
  description = "Gateway name"
  default     = "appgw_private_aks"
}

variable "appgwsubnet" {
  description = "Gateway Subnet name"
  default     = "subnet-JDIK-APPGW"
}


variable "spoke_resource_group_name" {
  description = "The resource group name to be created"
  default     = "RG-JDIK-DEV"
}

variable "nodepool_nodes_count" {
  description = "Default nodepool nodes count"
  default     = 1
}

variable "nodepool_vm_size" {
  description = "Default nodepool VM size"
  default     = "Standard_D2_v2"
}

variable "network_docker_bridge_cidr" {
  description = "CNI Docker bridge cidr"
  default     = "172.17.0.1/16"
}

variable "network_dns_service_ip" {
  description = "CNI DNS service IP"
  default     = "10.29.31.10"
}

variable "network_service_cidr" {
  description = "CNI service cidr"
  default     = "10.29.31.0/25"
}

variable "client_id" {
  description = "SP ID"
  
  
}

variable "client_secret" {
  description = "SP Secret"
  
}

variable "spname"{
  description = " SP Name"
  default = "http://RT-JDIK-SP-AKS-EON"
}

variable "dns_prefix" {
    default = "k8stest"
}

variable "subscription_id" {
    default = "e7f9758e-74f9-427e-bbdf-6cc2884369a4"
}
