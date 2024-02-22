variable "prefix" {
  type = string
  description = "Provide the Prefix name to be used"
}

variable "location" {
  type = list
  description = "Provide the Azure Location into which the REsource to be created."
}

variable "image_sku" {
  type = list
  description = "Provide the Image SKU Name"
}

variable "enable_disable_autoscale" {
  type = bool
  description = "Select the option for enable or disable the autoscale" 
}

variable "env" {
  type = list
  description = "Provide the Environment Name"
}
