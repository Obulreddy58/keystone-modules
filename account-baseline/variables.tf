# ─── Required ────────────────────────────────────────────────────────────────

variable "account_id" {
  description = "12-digit AWS account ID (the newly created account)"
  type        = string
}

variable "team_name" {
  description = "Team that owns this account"
  type        = string
}

variable "github_oidc_subjects" {
  description = "GitHub OIDC subject claims to allow (e.g. repo:org/repo:*)"
  type        = list(string)

  validation {
    condition     = length(var.github_oidc_subjects) > 0
    error_message = "At least one OIDC subject must be specified."
  }
}

# ─── Optional ────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "us-east-1"
}

variable "github_actions_role_name" {
  description = "Name for the GitHub Actions OIDC IAM role"
  type        = string
  default     = "github-actions-terraform"
}

variable "github_actions_policy_arn" {
  description = "IAM policy ARN to attach to the GitHub Actions role"
  type        = string
  default     = "arn:aws:iam::aws:policy/AdministratorAccess"
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail in this account"
  type        = bool
  default     = true
}

variable "central_logging_bucket" {
  description = "S3 bucket name in the log archive account for centralized CloudTrail"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all baseline resources"
  type        = map(string)
  default     = {}
}
