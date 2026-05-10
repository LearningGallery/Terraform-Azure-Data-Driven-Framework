variable "location" { type = string }
variable "tags" { type = map(string) }

variable "linux_vms" { type = map(any) }
variable "windows_vms" { type = map(any) }
variable "subnet_ids" { type = map(string) }

variable "ssh_public_key_path" { type = string }
variable "linux_bootstrap_script_path" { type = string }
variable "windows_admin_password" { 
  type      = string 
  sensitive = true
}
variable "windows_bootstrap_script_path" { type = string }