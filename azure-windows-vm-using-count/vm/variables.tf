variable "prefix" {
  type = string
  description = "Provide the Prefix for Resources to be created"
}

variable "vm_count" {
  type = number
  description = "Provide the number of VMs to be launched"
}

variable "vm_name" {
  type = string
  description = "Provide the VM Name prefix"
}

variable "availability_zone" {
  type = list
  description = "Provide the Availability Zone into which the VM to be created"
}

variable "val" {
  type = number
  default = null
}

variable "image_sku" {
  type = list
  description = "Provide the Image Sku for OS to be used"
}

variable "resource_group_name" {
  type = string
  description = "Resource Group Name into which VM will be created"
  default = ""
}

variable "subnet_id" {
  type = string
  description = "Subnet ID of the Subnet into which VM to be created"
  default = ""
}

variable "location" {
  type = list
  description = "Provide the Location for Resources to be created"
}

variable "subnet_name" {
  type = string
  description = "Provide the Subnet Name"
}

variable "vm_size" {
  type = list
  description = "Provide the Size of the Azure VM"
}

variable "static_dynamic" {
  type = list
  description = "Select the Static or Dynamic"
}

variable "disk_size_gb" {
  type = number
  description = "Provide the Disk Size in GB"
}

variable "env" {
  type = list
  description = "Select the Environment as dev, stage or prod"
}

variable "computer_name" {
  type = string
  description = "Provide the Hostname"
}

variable "admin_username" {
  type = string
  description = "Provid the Administrator Username"
}

variable "admin_password" {
  type = string
  description = "Provide the Administrator Password"
}
