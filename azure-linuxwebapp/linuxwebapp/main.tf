
module "linux_webapp" {
  source = "../module"
  prefix = var.prefix 
  location = var.location
  serviceplan_skuname = var.serviceplan_skuname[2]      ###  App Service Plan Premium V3 (P1v3) is selected.
  java_version = var.java_version[1]
  env = var.env[0]
}
