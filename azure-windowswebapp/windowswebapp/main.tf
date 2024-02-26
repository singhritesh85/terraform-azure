
module "linux_webapp" {
  source = "../module"
  prefix = var.prefix 
  location = var.location
  serviceplan_skuname = var.serviceplan_skuname[4]      ###  App Service Plan Premium V3 (P1v3) is selected.
  current_stack = var.current_stack[0]
  dotnet_version = var.dotnet_version[0]
  env = var.env[0]
}
