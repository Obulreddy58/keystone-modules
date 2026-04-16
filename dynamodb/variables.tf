variable "name" {
  description = "DynamoDB table name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "billing_mode" {
  description = "Billing mode: PAY_PER_REQUEST or PROVISIONED"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "hash_key" {
  description = "Partition key attribute name"
  type        = string
}

variable "hash_key_type" {
  description = "Partition key type (S, N, or B)"
  type        = string
  default     = "S"
}

variable "range_key" {
  description = "Sort key attribute name (optional)"
  type        = string
  default     = null
}

variable "range_key_type" {
  description = "Sort key type (S, N, or B)"
  type        = string
  default     = "S"
}

variable "read_capacity" {
  description = "Read capacity units (only for PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units (only for PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "enable_autoscaling" {
  description = "Enable auto-scaling for provisioned capacity"
  type        = bool
  default     = false
}

variable "autoscaling_read_min" {
  description = "Minimum read capacity for auto-scaling"
  type        = number
  default     = 5
}

variable "autoscaling_read_max" {
  description = "Maximum read capacity for auto-scaling"
  type        = number
  default     = 100
}

variable "autoscaling_write_min" {
  description = "Minimum write capacity for auto-scaling"
  type        = number
  default     = 5
}

variable "autoscaling_write_max" {
  description = "Maximum write capacity for auto-scaling"
  type        = number
  default     = 100
}

variable "autoscaling_target_utilization" {
  description = "Target utilization percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "enable_point_in_time_recovery" {
  description = "Enable Point-In-Time Recovery"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "table_class" {
  description = "Table class: STANDARD or STANDARD_INFREQUENT_ACCESS"
  type        = string
  default     = "STANDARD"
}

variable "ttl_attribute" {
  description = "TTL attribute name (empty string to disable)"
  type        = string
  default     = ""
}

variable "stream_enabled" {
  description = "Enable DynamoDB Streams"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Stream view type: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
}

variable "global_secondary_indexes" {
  description = "List of GSIs to create"
  type = list(object({
    name               = string
    hash_key           = string
    hash_key_type      = string
    range_key          = optional(string)
    range_key_type     = optional(string)
    projection_type    = string
    non_key_attributes = optional(list(string))
    read_capacity      = optional(number)
    write_capacity     = optional(number)
  }))
  default = []
}

variable "local_secondary_indexes" {
  description = "List of LSIs to create"
  type = list(object({
    name               = string
    range_key          = string
    range_key_type     = string
    projection_type    = string
    non_key_attributes = optional(list(string))
  }))
  default = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption (uses AWS owned key if not set)"
  type        = string
  default     = null
}

variable "replica_regions" {
  description = "List of regions for global table replicas"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
