variable "name" {
  description = "Function name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "description" {
  description = "Function description"
  type        = string
  default     = ""
}

variable "runtime" {
  description = "Lambda runtime (e.g. python3.12, nodejs20.x)"
  type        = string
}

variable "handler" {
  description = "Function handler"
  type        = string
  default     = "index.handler"
}

variable "filename" {
  description = "Path to the deployment package (.zip)"
  type        = string
  default     = ""
}

variable "s3_bucket" {
  description = "S3 bucket containing the deployment package"
  type        = string
  default     = ""
}

variable "s3_key" {
  description = "S3 key for the deployment package"
  type        = string
  default     = ""
}

variable "memory_size" {
  description = "Memory in MB"
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Timeout in seconds"
  type        = number
  default     = 30
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency (-1 = unreserved)"
  type        = number
  default     = -1
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for the function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

variable "policy_arns" {
  description = "Additional IAM policy ARNs to attach to the execution role"
  type        = list(string)
  default     = []
}

variable "dead_letter_target_arn" {
  description = "SQS queue or SNS topic ARN for dead letter queue"
  type        = string
  default     = ""
}

variable "tracing_mode" {
  description = "X-Ray tracing mode: Active or PassThrough"
  type        = string
  default     = "Active"
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
