variable "project_code" {
  description = "3-character project code (e.g., prj, app, sec)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3}$", var.project_code))
    error_message = "Project code must be exactly 3 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment (u=UAT, p=PROD)"
  type        = string
  default     = "u"
  validation {
    condition     = contains(["u", "p"], var.environment)
    error_message = "Environment must be 'u' (UAT) or 'p' (PROD)."
  }
}

variable "cost_center" {
  description = "Enterprise Billing Cost Center Code"
  type        = string
  validation {
    condition     = can(regex("^[A-Z0-9]{4,8}$", var.cost_center))
    error_message = "Cost Center must be 4-8 uppercase alphanumeric characters."
  }
}

variable "data_classification" {
  description = "Data classification level for security compliance"
  type        = string
  default     = "Confidential"
  validation {
    condition     = contains(["Public", "Internal", "Confidential", "Restricted"], var.data_classification)
    error_message = "Data Classification must be Public, Internal, Confidential, or Restricted."
  }
}

variable "location" {
  description = "Azure deployment region"
  type        = string
}
