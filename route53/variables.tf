variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
}

variable "comment" {
  description = "Comment for the hosted zone"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Whether to destroy all records when destroying the zone"
  type        = bool
  default     = false
}

variable "vpc_associations" {
  description = "List of VPC IDs to associate with a private hosted zone (empty = public zone)"
  type = list(object({
    vpc_id     = string
    vpc_region = optional(string)
  }))
  default = []
}

variable "records" {
  description = "Map of DNS records to create"
  type = map(object({
    type    = string
    ttl     = optional(number, 300)
    records = optional(list(string))
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, true)
    }))
    health_check_id = optional(string)
    set_identifier  = optional(string)
    weighted_routing_policy = optional(object({
      weight = number
    }))
    latency_routing_policy = optional(object({
      region = string
    }))
    failover_routing_policy = optional(object({
      type = string # PRIMARY or SECONDARY
    }))
  }))
  default = {}
}

variable "health_checks" {
  description = "Map of Route53 health checks to create"
  type = map(object({
    type                            = string # HTTP, HTTPS, TCP
    fqdn                            = optional(string)
    ip_address                      = optional(string)
    port                            = optional(number)
    resource_path                   = optional(string, "/")
    failure_threshold               = optional(number, 3)
    request_interval                = optional(number, 30)
    search_string                   = optional(string)
    measure_latency                 = optional(bool, false)
    regions                         = optional(list(string))
    enable_sni                      = optional(bool, true)
    cloudwatch_alarm_name           = optional(string)
    cloudwatch_alarm_region         = optional(string)
    insufficient_data_health_status = optional(string)
  }))
  default = {}
}

variable "enable_dnssec" {
  description = "Enable DNSSEC signing for the hosted zone"
  type        = bool
  default     = false
}

variable "delegation_set_id" {
  description = "Reusable delegation set ID"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
