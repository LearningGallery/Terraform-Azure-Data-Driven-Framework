output "nsg_ids" {
  description = "Map of Network Security Group names to their Azure IDs"
  value       = { for k, v in azurerm_network_security_group.main : k => v.id }
}

output "bastion_host_ids" {
  description = "Map of Bastion Host names to their Azure IDs"
  value       = { for k, v in azurerm_bastion_host.main : k => v.id }
}