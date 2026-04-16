variable "name" {
  description = "Name prefix for Transit Gateway resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "amazon_side_asn" {
  description = "Private ASN for the Transit Gateway"
  type        = number
  default     = 64512
}

variable "auto_accept_shared_attachments" {
  description = "Auto accept cross-account attachments"
  type        = string
  default     = "disable"
}

variable "default_route_table_association" {
  description = "Auto associate with default route table"
  type        = string
  default     = "enable"
}

variable "default_route_table_propagation" {
  description = "Auto propagate routes to default route table"
  type        = string
  default     = "enable"
}

variable "dns_support" {
  description = "Enable DNS support"
  type        = string
  default     = "enable"
}

variable "vpn_ecmp_support" {
  description = "Enable VPN ECMP support"
  type        = string
  default     = "enable"
}

variable "vpc_attachments" {
  description = "Map of VPC attachments"
  type = map(object({
    vpc_id                                          = string
    subnet_ids                                      = list(string)
    dns_support                                     = optional(string, "enable")
    transit_gateway_default_route_table_association  = optional(bool, true)
    transit_gateway_default_route_table_propagation  = optional(bool, true)
  }))
  default = {}
}

variable "ram_principals" {
  description = "List of AWS account IDs or OU ARNs to share the TGW with via RAM"
  type        = list(string)
  default     = []
}

variable "enable_flow_logs" {
  description = "Enable TGW flow logs"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Flow log retention in days"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
