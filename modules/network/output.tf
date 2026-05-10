output "vnet_ids" {
  description = "Map of Virtual Network names to their Azure IDs"
  value       = { for k, v in azurerm_virtual_network.main : k => v.id }
}

output "subnet_ids" {
  description = "Map of Subnet names to their Azure IDs"
  value       = { for k, v in azurerm_subnet.main : k => v.id }
}

output "public_ip_ids" {
  description = "Map of Public IP names to their Azure IDs"
  value       = { for k, v in azurerm_public_ip.main : k => v.id }
}

output "route_table_ids" {
  description = "Map of Route Table names to their Azure IDs"
  value       = { for k, v in azurerm_route_table.main : k => v.id }
}

output "dns_zone_ids" {
  description = "Map of DNS Zone names to their Azure IDs"
  value       = { for k, v in azurerm_private_dns_zone.main : k => v.id }
}