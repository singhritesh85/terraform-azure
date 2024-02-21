module "dns" {
  source         =  "../module" 
  prefix         = var.prefix
  location       = var.location
  dns_zone_name  = var.dns_zone_name
  a_reccord_name = var.a_reccord_name
  public_ip      = var.public_ip
}
