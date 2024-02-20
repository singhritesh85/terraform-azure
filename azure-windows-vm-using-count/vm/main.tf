module "azurevnet" {
  source = "../module_vnet"
#  count = var.vm_count
  prefix = var.prefix
  location = var.location[0]
  subnet_name = var.subnet_name
}

module "azurevm" {
  source = "../module_vm" 
  count = var.vm_count
  prefix = var.prefix 
  location = var.location[0]
  resource_group_name = module.azurevnet.resource_group_name
  subnet_id = module.azurevnet.subnet_id
#  subnet_name = var.subnet_name
  vm_size = var.vm_size[0]
  availability_zone = var.availability_zone
  image_sku = var.image_sku[1]
  val = count.index
  vm_name = "${var.vm_name}-${var.env[0]}-${count.index + 1}"
  static_dynamic = var.static_dynamic
  disk_size_gb = var.disk_size_gb
  env = var.env[0]
  computer_name = var.computer_name
  admin_username = var.admin_username
  admin_password = var.admin_password
}
