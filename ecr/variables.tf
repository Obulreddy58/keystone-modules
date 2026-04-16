variable "repositories" {
  description = "Map of ECR repositories to create"
  type = map(object({
    image_tag_mutability = optional(string, "IMMUTABLE")
    scan_on_push         = optional(bool, true)
    max_image_count      = optional(number, 30)
    encryption_type      = optional(string, "KMS")
  }))
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
