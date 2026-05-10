module "resource_group" {
  source = "../../../../modules/resourcegroup"

  location = var.location
  tags     = local.enterprise_tags
  # Inject the parsed CSV data map
  resource_groups = local.rgs
}

module "network" {
  source = "../../../../modules/network"
  depends_on = [module.resource_group]

  location = var.location
  tags     = local.enterprise_tags

  # Inject the parsed CSV data maps
  resource_groups = local.rgs
  vnets           = local.vnets
  pips            = local.pips
  subnets         = local.subnets
  route_tables    = { for k, v in local.route_tables : k => v[0] }
  rt_routes       = local.rt_routes
  natgws          = local.natgws
  dns_zones       = local.dns_zones
  dns_links       = local.dns_links
}

module "security" {
  source     = "../../../../modules/security"
  # Strictly waits for Network to finish before attaching security!
  depends_on = [module.network] 

  location = var.location
  tags     = local.enterprise_tags

  resource_groups = local.rgs
  nsgs            = { for k, v in local.nsgs : k => v[0] }
  nsg_rules       = local.nsg_rules
  bastions        = local.bastions
  subnets         = local.subnets

  # Dependency Injection: Passing Network IDs into the Security Module
  vnet_ids   = module.network.vnet_ids
  subnet_ids = module.network.subnet_ids
  pip_ids    = module.network.public_ip_ids
}

module "compute" {
  source     = "../../../../modules/compute"
  # Strictly waits for Network to be fully provisioned!
  depends_on = [module.network] 

  location = var.location
  tags     = local.enterprise_tags

  # Pass the OS-specific maps
  linux_vms   = local.linux_vms
  windows_vms = local.windows_vms

  # Dependency Injection: Pass the Subnet map from Network
  subnet_ids = module.network.subnet_ids

  # Bootstrap Scripts (Ensure these files exist in your root directory)
  ssh_public_key_path           = "./keys/id_rsa.pub"
  windows_admin_password        = "P@ssw0rd1234Enterprise!" # In prod, use Azure KeyVault!
  linux_bootstrap_script_path   = "./scripts/linux_bootstrap.sh"
  windows_bootstrap_script_path = "./scripts/windows_bootstrap.ps1"
}