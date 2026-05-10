# -------------------------------------------------------------------------
# Network Security Groups & Rules
# -------------------------------------------------------------------------
resource "azurerm_network_security_group" "main" {
  for_each = var.nsgs

  name                = each.value.SecurityGroupName
  location            = var.location
  resource_group_name = each.value.ResourceGroup
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = can(regex("^sgp-[a-z0-9]{3}-[up](ia|ie|mgmt)-[a-z]{3}-[a-z]{3}\\d{2}$", each.value.SecurityGroupName))
      error_message = "NSG name '${each.value.SecurityGroupName}' violates enterprise naming standards. Expected format: sgp-<3char>-<u|p><ia|ie|mgmt>-<3char>-<3char><2digits>."
    }
  }
}

resource "azurerm_network_security_rule" "main" {
  for_each = var.nsg_rules

  name                        = each.value.rule_name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  description                 = each.value.description
  resource_group_name         = each.value.rg_name
  network_security_group_name = each.value.nsg_name

  depends_on = [azurerm_network_security_group.main]
}

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = { for k, v in var.subnets : k => v if v.nsg_link != "None" }

  # Uses the Subnet ID injected from the network module!
  subnet_id                 = var.subnet_ids[each.key]
  network_security_group_id = azurerm_network_security_group.main[each.value.nsg_link].id
}

# -------------------------------------------------------------------------
# Azure Bastion
# -------------------------------------------------------------------------
resource "azurerm_bastion_host" "main" {
  for_each = var.bastions

  name                = each.value.BastionName
  location            = var.location
  resource_group_name = each.value.ResourceGroup
  sku                 = each.value.SkuName
  tags                = var.tags

  copy_paste_enabled     = tobool(each.value.CopyAndPaste)
  shareable_link_enabled = tobool(each.value.ShareableLink)

  virtual_network_id = each.value.SkuName == "Developer" ? var.vnet_ids[each.value.VirtualNetworkID] : null

  dynamic "ip_configuration" {
    for_each = each.value.SkuName != "Developer" ? [1] : []
    content {
      name                 = "configuration"
      subnet_id            = var.subnet_ids[each.value.SubnetID]
      public_ip_address_id = each.value.PublicIP != "None" ? var.pip_ids[each.value.PublicIP] : null
    }
  }

  lifecycle {
    precondition {
      condition     = can(regex("^bst-[a-z0-9]{3}-[up](ia|ie|mgmt)-\\d{2}$", each.value.BastionName))
      error_message = "Bastion name '${each.value.BastionName}' violates enterprise naming standards."
    }
  }
}
