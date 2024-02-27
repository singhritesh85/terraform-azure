variable "prefix" {
  type = string
  description = "Provide the globally unique prefix name to be used for creation of Azure Resources"
}

variable "location" {
  type = list
  description = "Provide the Location into which the Resource to be created"
}

variable "acr_sku" {
  type = list
  description = "Selection the SKU among Basic, Standard and Premium"
}

variable "admin_enabled" {
  type = bool
  description = "The ACR accessibility is Admin enabled or not."
}
