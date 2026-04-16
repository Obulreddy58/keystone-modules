variable "name" {
  description = "API Gateway name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "description" {
  description = "API description"
  type        = string
  default     = ""
}

variable "protocol_type" {
  description = "Protocol type: HTTP or WEBSOCKET"
  type        = string
  default     = "HTTP"
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain"
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "Stage name"
  type        = string
  default     = "$default"
}

variable "auto_deploy" {
  description = "Auto deploy stage on changes"
  type        = bool
  default     = true
}

variable "cors_configuration" {
  description = "CORS configuration"
  type = object({
    allow_origins     = list(string)
    allow_methods     = optional(list(string), ["GET", "POST", "PUT", "DELETE", "OPTIONS"])
    allow_headers     = optional(list(string), ["*"])
    expose_headers    = optional(list(string), [])
    max_age           = optional(number, 3600)
    allow_credentials = optional(bool, false)
  })
  default = null
}

variable "throttling_burst_limit" {
  description = "Throttling burst limit"
  type        = number
  default     = 500
}

variable "throttling_rate_limit" {
  description = "Throttling rate limit (requests/sec)"
  type        = number
  default     = 1000
}

variable "access_log_retention_days" {
  description = "Access log retention in days"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
