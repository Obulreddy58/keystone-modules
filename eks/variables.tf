variable "name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster and worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs (for ALB if needed)"
  type        = list(string)
  default     = []
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API server endpoint is publicly accessible"
  type        = bool
  default     = false
}

variable "cluster_endpoint_private_access" {
  description = "Whether the EKS API server endpoint is privately accessible"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public API endpoint"
  type        = list(string)
  default     = []
}

# Managed Node Group defaults
variable "node_group_defaults" {
  description = "Default configuration for managed node groups"
  type = object({
    instance_types = list(string)
    capacity_type  = string
    disk_size      = number
  })
  default = {
    instance_types = ["m6i.xlarge"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
  }
}

variable "node_groups" {
  description = "Map of managed node group configurations"
  type = map(object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = optional(list(string))
    capacity_type  = optional(string)
    disk_size      = optional(number)
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {
    general = {
      desired_size = 3
      min_size     = 3
      max_size     = 10
    }
  }
}

variable "enable_cluster_encryption" {
  description = "Enable envelope encryption for Kubernetes secrets"
  type        = bool
  default     = true
}

variable "cluster_log_types" {
  description = "List of control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain cluster logs"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
