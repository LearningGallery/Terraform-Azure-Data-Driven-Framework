output "linux_vm_ids" {
  description = "Map of Linux VM names to their Azure IDs"
  value       = { for k, v in azurerm_linux_virtual_machine.main : k => v.id }
}

output "windows_vm_ids" {
  description = "Map of Windows VM names to their Azure IDs"
  value       = { for k, v in azurerm_windows_virtual_machine.main : k => v.id }
}