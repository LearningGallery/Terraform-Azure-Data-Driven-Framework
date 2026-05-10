# -------------------------------------------------------------------------
# Resource Groups
# -------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  for_each = var.resource_groups

  name     = each.value.ResourceGroupName
  location = var.location
  tags     = var.tags

  lifecycle {
    precondition {
      condition     = can(regex("^rsg-[a-z0-9]{3}-[up](ia|ie|mgmt)-\\d{2}$", each.value.ResourceGroupName))
      error_message = "Resource Group name '${each.value.ResourceGroupName}' violates enterprise naming standards. Expected format: rsg-<3char>-<u|p><ia|ie|mgmt>-<2digits>."
    }
  }
}
