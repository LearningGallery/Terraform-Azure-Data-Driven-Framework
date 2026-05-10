# -------------------------------------------------------------------------
# Virtual Networks
# -------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  for_each = var.vnets

  name                = each.value.name
  location            = var.location
  resource_group_name = each.value.resource_group_name
  address_space       = each.value.address_space
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = can(regex("^vnt-[a-z0-9]{3}-[up](ia|ie|mgmt)-\\d{2}$", each.value.name))
      error_message = "VNet name '${each.value.name}' violates enterprise naming standards. Expected format: vnt-<3char>-<u|p><ia|ie|mgmt>-<2digits>."
    }
  }
}

# -------------------------------------------------------------------------
# Subnets & NSG Associations
# -------------------------------------------------------------------------
resource "azurerm_subnet" "main" {
  for_each = var.subnets

  name                 = each.value.name
  resource_group_name  = each.value.rg_name
  virtual_network_name = each.value.vnet_name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  lifecycle {
    precondition {
      # Validates standard naming OR strict Azure required names like AzureBastionSubnet
      condition     = can(regex("^(sub-[a-z0-9]{3}-[up](ia|ie|mgmt)-[a-z]{3}-[a-z]{3}\\d{2}|AzureBastionSubnet|GatewaySubnet)$", each.value.name))
      error_message = "Subnet name '${each.value.name}' violates enterprise naming standards. Expected format: sub-<3char>-<u|p><ia|ie|mgmt>-<3char>-<3char><2digits> or AzureBastionSubnet."
    }
  }

  depends_on = [azurerm_virtual_network.main]
}

# -------------------------------------------------------------------------
# Route Tables & Routes
# -------------------------------------------------------------------------
resource "azurerm_route_table" "main" {
  for_each = var.route_tables

  name                          = each.key
  location                      = var.location
  resource_group_name           = each.value.ResourceGroup
  bgp_route_propagation_enabled = !tobool(each.value.DisableBGP)
  tags                          = var.tags

  lifecycle {
    precondition {
      # Validates against your exact strict Tiered naming requirement
      condition     = can(regex("^rut-[a-z0-9]{3}-[up](ia|ie|mgmt)-\\d{2}$", each.key))
      error_message = "Route Table name '${each.key}' violates enterprise naming standards. Expected format: rut-<3char>-<u|p><ia|ie|mgmt>-<2digits>."
    }
  }
}

resource "azurerm_route" "main" {
  for_each = var.rt_routes

  name                   = each.value.route_name
  resource_group_name    = each.value.rg_name
  route_table_name       = each.value.rt_name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_ip

  depends_on = [azurerm_route_table.main]
}

# -------------------------------------------------------------------------
# Subnet <-> Route Table Association
# -------------------------------------------------------------------------
resource "azurerm_subnet_route_table_association" "main" {
  # Only loop through subnets that actually have a Route Table assigned in the CSV
  for_each = { for k, v in var.subnets : k => v if v.rt_link != "None" }

  subnet_id      = azurerm_subnet.main[each.key].id
  route_table_id = azurerm_route_table.main[each.value.rt_link].id
}

# -------------------------------------------------------------------------
# Public IPs
# -------------------------------------------------------------------------
resource "azurerm_public_ip" "main" {
  for_each = var.pips

  name                = each.value.PublicIPName
  location            = var.location
  resource_group_name = each.value.ResourceGroup
  allocation_method   = each.value.AllocationMethod
  sku                 = each.value.Sku
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = can(regex("^pip-[a-z0-9]{3}-[up](ia|ie|mgmt)-[a-z]{3}-[a-z]{3}\\d{2}$", each.value.PublicIPName))
      error_message = "Public IP name '${each.value.PublicIPName}' violates enterprise naming standards. Expected format: pip-<3char>-<u|p><ia|ie|mgmt>-<3char>-<3char><2digits>."
    }
  }
}

# -------------------------------------------------------------------------
# NAT Gateway
# -------------------------------------------------------------------------
resource "azurerm_nat_gateway" "main" {
  for_each = var.natgws

  name                = each.value.NATGateWayName
  location            = var.location
  resource_group_name = each.value.ResourceGroup
  sku_name            = each.value.SkuName
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = can(regex("^ngw-[a-z0-9]{3}-[up](ia|ie|mgmt)-[a-z]{3}-\\d{2}$", each.value.NATGateWayName))
      error_message = "NAT Gateway name '${each.value.NATGateWayName}' violates enterprise naming standards."
    }
  }
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  for_each = var.natgws

  nat_gateway_id       = azurerm_nat_gateway.main[each.key].id
  public_ip_address_id = azurerm_public_ip.main[each.value.PublicIPAddress].id
}

resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each = var.natgws

  subnet_id      = azurerm_subnet.main[each.value.SelectSpecificSubnets].id
  nat_gateway_id = azurerm_nat_gateway.main[each.key].id
}

# -------------------------------------------------------------------------
# Private DNS Zones & Virtual Network Links
# -------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "main" {
  for_each = var.dns_zones

  name                = each.key
  resource_group_name = each.value.ResourceGroup
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each = var.dns_links

  # Transforms vnt-prj-uia-01 directly into vnl-prj-uia-01
  name                  = replace(each.value.vnet_name, "vnt-", "vnl-")
  resource_group_name   = each.value.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.main[each.value.zone_name].name
  
  # Uses the VNet ID dynamically generated earlier in this module
  virtual_network_id    = azurerm_virtual_network.main[each.value.vnet_name].id
  tags                  = var.tags

  lifecycle {
    precondition {
      # Validates the dynamically generated name against the strict vnl- standard
      condition     = can(regex("^vnl-[a-z0-9]{3}-[up](ia|ie|mgmt)-\\d{2}$", replace(each.value.vnet_name, "vnt-", "vnl-")))
      error_message = "Virtual Network Link name '${replace(each.value.vnet_name, "vnt-", "vnl-")}' violates enterprise naming standards. Expected format: vnl-<3char>-<u|p><ia|ie|mgmt>-<2digits>."
    }
  }
}