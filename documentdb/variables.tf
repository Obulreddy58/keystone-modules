variable "name" {
  description = "Name prefix for all DocumentDB resources"
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

variable "database_subnet_ids" {
  description = "List of subnet IDs for the DocumentDB subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to connect to DocumentDB"
  type        = list(string)
}

variable "engine_version" {
  description = "DocumentDB engine version (MongoDB compatibility)"
  type        = string
  default     = "5.0"
}

variable "instance_class" {
  description = "DocumentDB instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "num_instances" {
  description = "Number of cluster instances"
  type        = number
  default     = 3
}

variable "master_username" {
  description = "Master username for DocumentDB"
  type        = string
  default     = "docdbadmin"
}

variable "port" {
  description = "DocumentDB port"
  type        = number
  default     = 27017
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Auto minor version upgrade for instances"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
