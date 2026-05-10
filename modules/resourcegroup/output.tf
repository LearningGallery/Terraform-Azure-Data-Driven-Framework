output "resource_group_ids" {
  description = "Map of Resource Group names to their Azure IDs"
  value       = { for k, v in azurerm_resource_group.main : k => v.id }
}