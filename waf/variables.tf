variable "name" {
  description = "Name prefix for WAF resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "scope" {
  description = "WAF scope: REGIONAL (ALB, API GW) or CLOUDFRONT"
  type        = string
  default     = "REGIONAL"
}

variable "resource_arns" {
  description = "List of resource ARNs to associate with the WAF (ALB, API Gateway, etc.)"
  type        = list(string)
  default     = []
}

variable "rate_limit" {
  description = "Rate limit per 5-minute window per IP"
  type        = number
  default     = 2000
}

variable "ip_rate_limit" {
  description = "Strict rate limit for aggressive IPs"
  type        = number
  default     = 500
}

variable "enable_aws_managed_rules" {
  description = "Enable AWS managed rule groups"
  type        = bool
  default     = true
}

variable "enable_sql_injection_rule" {
  description = "Enable SQL injection protection"
  type        = bool
  default     = true
}

variable "enable_xss_rule" {
  description = "Enable XSS protection"
  type        = bool
  default     = true
}

variable "enable_bad_inputs_rule" {
  description = "Enable known bad inputs protection"
  type        = bool
  default     = true
}

variable "enable_ip_reputation_rule" {
  description = "Enable Amazon IP reputation list"
  type        = bool
  default     = true
}

variable "enable_bot_control" {
  description = "Enable Bot Control managed rule group"
  type        = bool
  default     = false
}

variable "blocked_ip_addresses" {
  description = "List of IP addresses/CIDRs to block"
  type        = list(string)
  default     = []
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses/CIDRs to always allow"
  type        = list(string)
  default     = []
}

variable "enable_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
