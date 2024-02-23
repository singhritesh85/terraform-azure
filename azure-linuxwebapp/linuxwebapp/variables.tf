variable "prefix" {
  type = string
  description = "Provide the Prefix Name to be used for creation of Azure Resources"
}

variable "location" {
  type = list
  description = "Provide the Location into which the Azure Resources will be created"
}

variable "serviceplan_skuname" {
  type = list
  description = "Provide the Service Plan SKU Name"
}

variable "java_version" {
  type = list
  description = "Provide the JAVA Version to be used"
}

variable "env" {
  type = list
  description = "Select the Environment Name"
}
