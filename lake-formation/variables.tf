variable "data_lake_name" {
  description = "Data lake identifier"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "admin_arn" {
  description = "IAM ARN for Lake Formation admin"
  type        = string
}

variable "s3_locations" {
  description = "S3 bucket ARNs to register as data lake locations"
  type        = list(string)
}

variable "lf_tags" {
  description = "LF-Tags (key → allowed values)"
  type        = map(list(string))
  default     = {}
}

variable "catalog_id" {
  description = "Glue Catalog ID (defaults to current account)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
