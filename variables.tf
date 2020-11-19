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


variable "routtablename" {
  description = "Route Table Name"
  default     = "RT-JDIK-DEV"
}

variable "akssubnet" {
  description = "AKS Subnet name"
  default     = "subnet-JDIK-DEV"
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
  default     = ""
}

variable "client_secret" {
  description = "SP Secret"
  default     = ""
}

variable "dns_prefix" {
    default = "k8stest"
}

