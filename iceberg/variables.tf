variable "database_name" {
  description = "Glue database name"
  type        = string
}

variable "table_name" {
  description = "Iceberg table name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "s3_bucket_name" {
  description = "Existing S3 bucket for data lake storage (auto-created if empty)"
  type        = string
  default     = ""
}

variable "file_format" {
  description = "Default file format for Iceberg table"
  type        = string
  default     = "parquet"
}

variable "compression" {
  description = "Compression codec"
  type        = string
  default     = "snappy"
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
