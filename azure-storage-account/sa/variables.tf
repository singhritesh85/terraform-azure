variable "prefix" {
  type = string
  description = "Provide the prefix name for the Resource to be created."
}

variable "location" {
  type = list
  description = "Provide the Location into which the Azure Resources to be created."
}

variable "account_tier" {
  type = list
  description = "Provide the Account Tier, For BlockBlobStorage and FileStorage accounts only Premium is valid."
}

variable "account_replication_type" {
  type = list
  description = "It defines the type of replication to use for this storage account."
}

variable "env" {
  type = list
  description = "Provide the Environment Name."
}

variable "min_tls_version" {
  type = list
  description = "Provide the Minimum TLS supported version"
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
