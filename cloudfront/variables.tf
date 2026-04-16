variable "name" {
  description = "Name prefix for CloudFront resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aliases" {
  description = "CNAMEs (alternate domain names)"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1)"
  type        = string
  default     = ""
}

variable "default_root_object" {
  description = "Default root object"
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "Price class (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_100"
}

variable "s3_origin" {
  description = "S3 origin configuration"
  type = object({
    bucket_regional_domain_name = string
    origin_id                   = string
  })
  default = null
}

variable "alb_origin" {
  description = "ALB origin configuration"
  type = object({
    domain_name = string
    origin_id   = string
    http_port   = optional(number, 80)
    https_port  = optional(number, 443)
    protocol    = optional(string, "https-only")
  })
  default = null
}

variable "default_cache_behavior" {
  description = "Default cache behavior"
  type = object({
    allowed_methods        = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods         = optional(list(string), ["GET", "HEAD"])
    viewer_protocol_policy = optional(string, "redirect-to-https")
    compress               = optional(bool, true)
    min_ttl                = optional(number, 0)
    default_ttl            = optional(number, 3600)
    max_ttl                = optional(number, 86400)
  })
  default = {}
}

variable "custom_error_responses" {
  description = "Custom error response configurations"
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number, 300)
  }))
  default = []
}

variable "geo_restriction_type" {
  description = "Geo restriction type (none, whitelist, blacklist)"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "web_acl_id" {
  description = "WAFv2 Web ACL ARN to associate"
  type        = string
  default     = ""
}

variable "enable_logging" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = true
}

variable "logging_bucket" {
  description = "S3 bucket domain for access logs"
  type        = string
  default     = ""
}

variable "logging_prefix" {
  description = "S3 prefix for access logs"
  type        = string
  default     = "cloudfront/"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
