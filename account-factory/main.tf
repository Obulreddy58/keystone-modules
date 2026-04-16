###############################################################################
# Account Factory — creates AWS accounts in an Organization
#
# The product owner requests an account.  After approval the platform runs
# this module, which:
#  1. Creates the account in the target OU
#  2. Assumes the OrganizationAccountAccessRole to bootstrap baseline
#  3. Registers the account outputs (id, role ARN, etc.)
###############################################################################

data "aws_organizations_organization" "this" {}

# ─── Create the account ─────────────────────────────────────────────────────

resource "aws_organizations_account" "team" {
  name                       = var.account_name
  email                      = var.account_email
  parent_id                  = var.ou_id
  role_name                  = var.admin_role_name
  iam_user_access_to_billing = var.iam_user_access_to_billing
  close_on_deletion          = var.close_on_deletion

  tags = merge(var.tags, {
    Team        = var.team_name
    CostCenter  = var.cost_center
    Environment = var.environment
    ManagedBy   = "self-service-platform"
  })

  lifecycle {
    # Prevent accidental deletion of an entire AWS account
    prevent_destroy = true
    ignore_changes  = [role_name]
  }
}

# ─── Move to the correct OU (if parent_id changed) ──────────────────────────

# The account is placed in the target OU at creation time via parent_id.
# If you want to support OU moves later, you'd add an
# aws_organizations_organizational_unit_membership resource here.

# ─── SSO / Identity Center permission set (optional) ────────────────────────

resource "aws_ssoadmin_account_assignment" "admin" {
  count = var.enable_sso_assignment ? 1 : 0

  instance_arn       = var.sso_instance_arn
  permission_set_arn = var.sso_admin_permission_set_arn

  principal_id   = var.sso_group_id
  principal_type = "GROUP"

  target_id   = aws_organizations_account.team.id
  target_type = "AWS_ACCOUNT"
}

# ─── Delegate GuardDuty to the new account (via the security account) ───────

resource "aws_guardduty_member" "team" {
  count = var.enable_guardduty ? 1 : 0

  account_id                 = aws_organizations_account.team.id
  detector_id                = var.guardduty_detector_id
  email                      = var.account_email
  invite                     = true
  disable_email_notification = true
}
