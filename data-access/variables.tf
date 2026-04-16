variable "access_name" {
  description = "Access provisioning name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "target_resource_type" {
  description = "Type of data resource (s3, rds, dynamodb, msk, documentdb, glue, redshift)"
  type        = string
}

variable "target_resource_arn" {
  description = "ARN of the target resource"
  type        = string
}

variable "principal_arns" {
  description = "IAM ARNs to grant access"
  type        = list(string)
}

variable "access_level" {
  description = "Access level (readonly, readwrite, admin)"
  type        = string
  default     = "readonly"
}

variable "enable_cross_account" {
  description = "Enable cross-account trust relationship"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
