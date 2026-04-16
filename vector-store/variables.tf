variable "name" {
  description = "Vector store name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "engine" {
  description = "Vector database engine (pgvector or opensearch-serverless)"
  type        = string
  default     = "pgvector"
}

variable "dimensions" {
  description = "Embedding dimensions"
  type        = number
  default     = 1536
}

variable "distance_metric" {
  description = "Distance metric (cosine, euclidean, inner_product)"
  type        = string
  default     = "cosine"
}

variable "instance_class" {
  description = "Instance class (pgvector only)"
  type        = string
  default     = "db.r6g.large"
}

variable "master_username" {
  description = "Master username (pgvector only)"
  type        = string
  default     = "vectoradmin"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "database_subnet_ids" {
  description = "Database subnet IDs (pgvector only)"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect"
  type        = list(string)
  default     = []
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
