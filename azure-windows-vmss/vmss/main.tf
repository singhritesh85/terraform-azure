module "vmss" {
  source    = "../module"
  prefix    = var.prefix
  location  = var.location 
  image_sku = var.image_sku[1]
  enable_disable_autoscale = var.enable_disable_autoscale
  env       = var.env[0]
}
