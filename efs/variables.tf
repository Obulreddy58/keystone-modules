variable "name" {
  description = "Name for the EFS file system"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the mount target security group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for mount targets (typically private subnets)"
  type        = list(string)
}

variable "performance_mode" {
  description = "EFS performance mode (generalPurpose or maxIO)"
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Must be generalPurpose or maxIO."
  }
}

variable "throughput_mode" {
  description = "EFS throughput mode (bursting, provisioned, or elastic)"
  type        = string
  default     = "elastic"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "Must be bursting, provisioned, or elastic."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "Provisioned throughput in MiB/s (only when throughput_mode is provisioned)"
  type        = number
  default     = null
}

variable "encrypted" {
  description = "Whether to encrypt the file system"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (uses aws/elasticfilesystem if not set)"
  type        = string
  default     = null
}

variable "lifecycle_policy_transition_to_ia" {
  description = "Move files to IA storage after N days (AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS)"
  type        = string
  default     = "AFTER_30_DAYS"
}

variable "lifecycle_policy_transition_to_primary" {
  description = "Move files back to primary on access (AFTER_1_ACCESS or null to disable)"
  type        = string
  default     = "AFTER_1_ACCESS"
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to mount the file system (e.g., EKS node SG)"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to mount the file system"
  type        = list(string)
  default     = []
}

variable "access_points" {
  description = "Map of EFS access points to create"
  type = map(object({
    posix_user = object({
      uid = number
      gid = number
    })
    root_directory = object({
      path = string
      creation_info = object({
        owner_uid   = number
        owner_gid   = number
        permissions = string
      })
    })
  }))
  default = {}
}

variable "enable_backup" {
  description = "Enable automatic backups via AWS Backup"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
