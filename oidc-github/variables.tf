variable "name" {
  description = "Name prefix for the IAM role"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or user name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "allowed_branches" {
  description = "List of branches allowed to assume the role (e.g. ['main', 'develop'])"
  type        = list(string)
  default     = ["main"]
}

variable "oidc_thumbprint" {
  description = "GitHub OIDC thumbprint (rarely changes)"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the deploy role"
  type        = list(string)
  default     = []
}

variable "create_default_policy" {
  description = "Create a default policy with broad infra permissions"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
