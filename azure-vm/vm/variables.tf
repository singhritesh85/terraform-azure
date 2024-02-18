variable "prefix" {
  type = string
  description = "Provide the Prefix for Resources to be created"
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

variable "availability_zone" {
  type = list
  description = "Provide the Availability Zone into which the VM to be created"
}

variable "static_dynamic" {
  type = list
  description = "Select the Static or Dynamic"
}

variable "disk_size_gb" {
  type = number
  description = "Provide the Disk Size in GB"
}

variable "extra_disk_size_gb" {
  type = number
  description = "Provide the Size of Extra Disk to be Attached"
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
