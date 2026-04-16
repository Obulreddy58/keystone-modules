variable "name" {
  description = "Name for the ElastiCache replication group"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the cache subnet group"
  type        = list(string)
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.r7g.large"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the replication group"
  type        = number
  default     = 2
}

variable "port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "parameter_group_family" {
  description = "Parameter group family"
  type        = string
  default     = "redis7"
}

variable "parameters" {
  description = "Map of Redis parameter overrides"
  type        = map(string)
  default     = {}
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (requires num_cache_clusters >= 2)"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ"
  type        = bool
  default     = true
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in transit (TLS)"
  type        = bool
  default     = true
}

variable "transit_encryption_mode" {
  description = "Transit encryption mode: preferred or required"
  type        = string
  default     = "required"
}

variable "kms_key_arn" {
  description = "KMS key ARN for at-rest encryption"
  type        = string
  default     = null
}

variable "auth_token" {
  description = "AUTH token (password) for Redis. Required when transit_encryption_enabled is true"
  type        = string
  default     = null
  sensitive   = true
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots (0 to disable)"
  type        = number
  default     = 7
}

variable "snapshot_window" {
  description = "Daily time range for automatic snapshots (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window (UTC)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "notification_topic_arn" {
  description = "SNS topic ARN for ElastiCache notifications"
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to Redis"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to Redis"
  type        = list(string)
  default     = []
}

variable "log_delivery_configuration" {
  description = "Log delivery configuration for slow-log and engine-log"
  type = list(object({
    destination      = string
    destination_type = string # cloudwatch-logs or kinesis-firehose
    log_format       = string # text or json
    log_type         = string # slow-log or engine-log
  }))
  default = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
