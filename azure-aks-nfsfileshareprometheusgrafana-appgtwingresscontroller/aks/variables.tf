variable "prefix" {
  type = string
  description = "Provide the Prefix Name" 
}

variable "location" {
  type = list
  description = "Provide the Location for Azure Resource to be created"
}

variable "kubernetes_version" {
  type = list
  description = "Provide the Kubernetes Version"
}

variable "ssh_public_key" {
  type = string
  description = "Provide the file name which keep the ssh public key"
}

variable "action_group_shortname" {
  type = string
  description = "Provide the short name for Azure Action Group"
}

variable "monitoring_namespace" {
  type = string
  description = "Provide name of the Kubernetes Namespace to be created"
}

variable "k8s_management_node_rg" {
  type = string
  description = "Provide the Resource Group Name for Terraform-Server or k8s-management-node's vnet"
}

variable "k8s_management_node_vnet" {
  type = string
  description = "Provide the k8s-management-node or Terraform-Server's vnet name"
}

variable "k8s_management_node_vnet_id" {
  type = string
  description = "Provide the k8s-management-node or Terraform-Server's vnet id"
}

variable "env" {
  type = list
  description = "Provide the Environment for AKS Cluster"
}

