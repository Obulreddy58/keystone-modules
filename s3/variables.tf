variable "name" {
  description = "Bucket name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "versioning" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow bucket deletion even with objects"
  type        = bool
  default     = false
}

variable "enable_kms_encryption" {
  description = "Use KMS encryption (if false, uses AES256)"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules"
  type = list(object({
    id                       = string
    enabled                  = optional(bool, true)
    prefix                   = optional(string, "")
    transition_days          = optional(number, 90)
    transition_storage_class = optional(string, "STANDARD_IA")
    expiration_days          = optional(number, 0)
    noncurrent_expiration    = optional(number, 90)
  }))
  default = []
}

variable "cors_rules" {
  description = "CORS configuration"
  type = list(object({
    allowed_headers = optional(list(string), ["*"])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3600)
  }))
  default = []
}

variable "cloudfront_distribution_arns" {
  description = "CloudFront distribution ARNs allowed to access this bucket via OAC"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
