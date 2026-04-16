variable "name" {
  description = "Name prefix for ALB resources"
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
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "internal" {
  description = "Whether the ALB is internal"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Idle timeout in seconds"
  type        = number
  default     = 60
}

variable "drop_invalid_header_fields" {
  description = "Drop invalid HTTP header fields"
  type        = bool
  default     = true
}

variable "enable_access_logs" {
  description = "Enable access logs to S3"
  type        = bool
  default     = true
}

variable "access_logs_bucket" {
  description = "S3 bucket for access logs (required if enable_access_logs = true)"
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "S3 prefix for access logs"
  type        = string
  default     = "alb-logs"
}

variable "target_groups" {
  description = "Map of target groups to create"
  type = map(object({
    port                 = number
    protocol             = optional(string, "HTTP")
    target_type          = optional(string, "ip")
    deregistration_delay = optional(number, 30)
    health_check = optional(object({
      enabled             = optional(bool, true)
      path                = optional(string, "/health")
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTP")
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
      interval            = optional(number, 30)
      timeout             = optional(number, 5)
      matcher             = optional(string, "200")
    }), {})
    stickiness = optional(object({
      enabled         = optional(bool, false)
      type            = optional(string, "lb_cookie")
      cookie_duration = optional(number, 86400)
    }), {})
  }))
  default = {}
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
