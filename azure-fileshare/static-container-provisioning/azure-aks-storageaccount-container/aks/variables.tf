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

variable "account_tier" {
  type = list
  description = "Provide the Account Tier, For BlockBlobStorage and FileStorage accounts only Premium is valid."
}

variable "account_replication_type" {
  type = list
  description = "It defines the type of replication to use for this storage account."
}

variable "min_tls_version" {
  type = list
  description = "Provide the Minimum TLS supported version"
}

variable "container_name" {
  type = string
  description = "Provider the Container Name"
}

variable "container_access_type" {
  type = list
  description = "Select the container access type from the given list"
}

variable "access_tier" {
  type = list
  description = "Select between Hot and Cold"
}

variable "routing_choice" {
  type = list
  description = "Select the Routing choice between InternetRouting and MicrosoftRouting. Defaults to MicrosoftRouting"
}

variable "container_delete_retaintion" {
  type = number
  description = "Provide the number of days the container should be retained"
}

variable "blob_delete_retaintion" {
  type = number
  description = "Provide the number of days that the blob should be retained"
}

variable "env" {
  type = list
  description = "Provide the Environment for AKS Cluster"
}

