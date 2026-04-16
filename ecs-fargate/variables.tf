variable "name" {
  description = "Name prefix for all ECS resources"
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

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "services" {
  description = "Map of ECS services to create"
  type = map(object({
    cpu                = number
    memory             = number
    container_port     = number
    desired_count      = number
    min_count          = optional(number, 1)
    max_count          = optional(number, 10)
    image              = string
    health_check_path  = optional(string, "/health")
    environment_vars   = optional(map(string), {})
    secrets            = optional(map(string), {})
    target_group_arn   = optional(string, "")
    assign_public_ip   = optional(bool, false)
    enable_autoscaling = optional(bool, true)
    cpu_threshold      = optional(number, 70)
  }))
  default = {}
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = true
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to reach ECS tasks"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
