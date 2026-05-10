# =========================================================================
# LINUX COMPUTE BLOCK
# =========================================================================
resource "azurerm_network_interface" "linux" {
  for_each            = var.linux_vms
  name                = "${each.value.computed_name}-nic01"
  location            = var.location
  resource_group_name = each.value.ResourceGroup

  ip_configuration {
    name                          = "internal"
    # Dynamically maps the CSV SubnetName to the actual Azure Subnet ID
    subnet_id                     = var.subnet_ids[each.value.SubnetName]
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "main" {
  for_each = var.linux_vms

  name                = each.value.computed_name
  computer_name       = replace(replace(each.value.computed_name, "vm-", ""), "-", "")
  location            = var.location
  resource_group_name = each.value.ResourceGroup
  size                = each.value.AzureVMSeries
  zone                = each.value.AvailabilityZone != "None" ? each.value.AvailabilityZone : null
  admin_username      = "azureuser"

  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_public_key_path)
  }

  network_interface_ids = [azurerm_network_interface.linux[each.key].id]

  os_disk {
    name                 = "${each.value.computed_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = each.value.DiskType
    disk_size_gb         = tonumber(each.value.OSStorageGB)
  }

  source_image_reference {
    publisher = each.value.ImagePublisher
    offer     = each.value.ImageOffer
    sku       = each.value.ImageSKU
    version   = each.value.ImageVersion
  }

  identity { type = "SystemAssigned" }
  custom_data = base64encode(file(var.linux_bootstrap_script_path))
  tags        = var.tags

  lifecycle {
    precondition {
      condition     = can(regex("^vm-[a-z0-9]{3}-[up](ia|ie|mgmt)-[a-z]{3}-[a-z]{3}\\d{2}$", each.value.computed_name))
      error_message = "Linux VM name '${each.value.computed_name}' violates standards. Expected: vm-<3char>-<u|p><ia|ie|mgmt>-<3char>-<3char><2digits>."
    }
  }
}

# -------------------------------------------------------------------------
# Linux Data Disks (Only created if DataStorageGB is NOT "None" or "0")
# -------------------------------------------------------------------------
resource "azurerm_managed_disk" "linux_data" {
  for_each = { for k, v in var.linux_vms : k => v if v.DataStorageGB != "None" && v.DataStorageGB != "0" }

  name                 = "${each.value.computed_name}-datadisk01"
  location             = var.location
  resource_group_name  = each.value.ResourceGroup
  zone                 = each.value.AvailabilityZone != "None" ? each.value.AvailabilityZone : null
  storage_account_type = each.value.DiskType
  create_option        = "Empty"
  disk_size_gb         = tonumber(each.value.DataStorageGB)
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "linux" {
  for_each = { for k, v in var.linux_vms : k => v if v.DataStorageGB != "None" && v.DataStorageGB != "0" }

  managed_disk_id    = azurerm_managed_disk.linux_data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[each.key].id
  lun                = 0
  caching            = "ReadWrite"
}


# =========================================================================
# WINDOWS COMPUTE BLOCK
# =========================================================================
resource "azurerm_network_interface" "windows" {
  for_each            = var.windows_vms
  name                = "${each.value.computed_name}-nic01"
  location            = var.location
  resource_group_name = each.value.ResourceGroup

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_ids[each.value.SubnetName]
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

resource "azurerm_windows_virtual_machine" "main" {
  for_each = var.windows_vms

  # ARM Portal Name (Up to 64 chars)
  name                = each.value.computed_name
  
  # INTERNAL OS NAME: Strips hyphens and enforces strict 15-character Windows limit
  computer_name       = substr(replace(replace(each.value.computed_name, "vm-", ""), "-", ""), 0, 15)
  location            = var.location
  resource_group_name = each.value.ResourceGroup
  size                = each.value.AzureVMSeries
  zone                = each.value.AvailabilityZone != "None" ? each.value.AvailabilityZone : null
  admin_username      = "azureadmin"
  admin_password      = var.windows_admin_password

  network_interface_ids = [azurerm_network_interface.windows[each.key].id]

  os_disk {
    name                 = "${each.value.computed_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = each.value.DiskType
    disk_size_gb         = tonumber(each.value.OSStorageGB)
  }

  source_image_reference {
    publisher = each.value.ImagePublisher
    offer     = each.value.ImageOffer
    sku       = each.value.ImageSKU
    version   = each.value.ImageVersion
  }

  identity { type = "SystemAssigned" }
  tags = var.tags

  lifecycle {
    precondition {
      condition     = can(regex("^vm-[a-z0-9]{3}-[up](ia|ie|mgmt)-[a-z]{3}-[a-z]{3}\\d{2}$", each.value.computed_name))
      error_message = "Windows VM name '${each.value.computed_name}' violates standards. Expected: vm-<3char>-<u|p><ia|ie|mgmt>-<3char>-<3char><2digits>."
    }
  }
}

# -------------------------------------------------------------------------
# Windows Data Disks
# -------------------------------------------------------------------------
resource "azurerm_managed_disk" "windows_data" {
  for_each = { for k, v in var.windows_vms : k => v if v.DataStorageGB != "None" && v.DataStorageGB != "0" }

  name                 = "${each.value.computed_name}-datadisk01"
  location             = var.location
  resource_group_name  = each.value.ResourceGroup
  zone                 = each.value.AvailabilityZone != "None" ? each.value.AvailabilityZone : null
  storage_account_type = each.value.DiskType
  create_option        = "Empty"
  disk_size_gb         = tonumber(each.value.DataStorageGB)
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "windows" {
  for_each = { for k, v in var.windows_vms : k => v if v.DataStorageGB != "None" && v.DataStorageGB != "0" }

  managed_disk_id    = azurerm_managed_disk.windows_data[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.main[each.key].id
  lun                = 0
  caching            = "ReadWrite"
}

# -------------------------------------------------------------------------
# Windows Custom Script Extension
# -------------------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "windows_bootstrap" {
  for_each = var.windows_vms

  name                 = "bootstrap"
  virtual_machine_id   = azurerm_windows_virtual_machine.main[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.windows
  ]

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(file(var.windows_bootstrap_script_path), "UTF-16LE")}"
  })
  tags = var.tags
}