# ─── Required ────────────────────────────────────────────────────────────────

variable "account_name" {
  description = "AWS account name (e.g. 'team-payments-prod')"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,49}$", var.account_name))
    error_message = "Account name must be 3-50 lowercase alphanumeric chars or hyphens."
  }
}

variable "account_email" {
  description = "Root email for the account (unique across all AWS accounts globally)"
  type        = string
}

variable "ou_id" {
  description = "Organizational Unit ID to place the account in (e.g. ou-xxxx-xxxxxxxx)"
  type        = string
}

variable "team_name" {
  description = "Team that owns this account"
  type        = string
}

variable "environment" {
  description = "Environment label (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ─── Optional ────────────────────────────────────────────────────────────────

variable "cost_center" {
  description = "Cost center tag for billing"
  type        = string
  default     = ""
}

variable "admin_role_name" {
  description = "IAM role name created automatically in the new account"
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "iam_user_access_to_billing" {
  description = "Allow IAM users to access billing in the new account"
  type        = string
  default     = "DENY"
}

variable "close_on_deletion" {
  description = "Close the account when the resource is destroyed"
  type        = bool
  default     = false
}

# ─── SSO / Identity Center ──────────────────────────────────────────────────

variable "enable_sso_assignment" {
  description = "Assign an SSO permission set to the team group"
  type        = bool
  default     = false
}

variable "sso_instance_arn" {
  description = "AWS SSO instance ARN"
  type        = string
  default     = ""
}

variable "sso_admin_permission_set_arn" {
  description = "SSO permission set ARN for the team admin role"
  type        = string
  default     = ""
}

variable "sso_group_id" {
  description = "Identity Center group ID for the team (product owner's group)"
  type        = string
  default     = ""
}

# ─── Security ───────────────────────────────────────────────────────────────

variable "enable_guardduty" {
  description = "Enable GuardDuty membership for this account"
  type        = bool
  default     = false
}

variable "guardduty_detector_id" {
  description = "GuardDuty detector ID from the security/delegated admin account"
  type        = string
  default     = ""
}

# ─── Tags ────────────────────────────────────────────────────────────────────

variable "tags" {
  description = "Additional tags to apply to the account"
  type        = map(string)
  default     = {}
}
