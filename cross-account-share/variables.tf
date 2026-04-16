variable "share_name" {
  description = "Resource share name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "resource_arns" {
  description = "ARNs of resources to share"
  type        = list(string)
}

variable "target_account_ids" {
  description = "Target AWS account IDs"
  type        = list(string)
}

variable "permission_type" {
  description = "Permission type (readonly, readwrite)"
  type        = string
  default     = "readonly"
}

variable "enable_external_sharing" {
  description = "Allow sharing outside the Organization"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for granting cross-account decryption (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
