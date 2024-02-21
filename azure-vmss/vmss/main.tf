module "vmss" {
  source   = "../module"
  prefix   = var.prefix
  location = var.location 
}
