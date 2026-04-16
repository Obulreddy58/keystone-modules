variable "classification_name" {
  description = "Classification job name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "target_bucket_arns" {
  description = "S3 bucket ARNs to classify"
  type        = list(string)
}

variable "sensitivity_level" {
  description = "Data sensitivity level (public, internal, confidential, restricted)"
  type        = string
  default     = "confidential"
}

variable "enable_pii_detection" {
  description = "Enable PII detection"
  type        = bool
  default     = true
}

variable "schedule_frequency" {
  description = "Classification schedule (daily, weekly, monthly)"
  type        = string
  default     = "weekly"
}

variable "notification_email" {
  description = "Email for classification findings"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
