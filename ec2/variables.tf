variable "name" {
  description = "Name prefix for EC2 resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for instance placement"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID (leave empty to use latest Amazon Linux 2023)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "SSH key pair name (leave empty for SSM-only access)"
  type        = string
  default     = ""
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "root_volume_encrypted" {
  description = "Encrypt root volume"
  type        = bool
  default     = true
}

variable "ebs_optimized" {
  description = "Enable EBS optimization"
  type        = bool
  default     = true
}

variable "monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "metadata_http_tokens" {
  description = "IMDSv2 enforcement (required = IMDSv2 only)"
  type        = string
  default     = "required"
}

variable "associate_public_ip" {
  description = "Associate public IP"
  type        = bool
  default     = false
}

variable "ingress_rules" {
  description = "Ingress rules for the security group"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
    description     = string
  }))
  default = []
}

variable "user_data" {
  description = "User data script (base64-encoded)"
  type        = string
  default     = ""
}

variable "iam_policies" {
  description = "Additional IAM policy ARNs to attach to the instance role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
