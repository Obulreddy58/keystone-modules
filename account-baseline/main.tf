###############################################################################
# Account Baseline — applied to every new account after creation
#
# Bootstraps the minimum security & operational posture:
#  1. OIDC role for GitHub Actions (so CI/CD can deploy)
#  2. Default VPC (optional — team can request a custom one later)
#  3. S3 bucket for Terraform state
#  4. CloudTrail → central log archive
#  5. AWS Config rules
#  6. GuardDuty (auto-enabled via org delegation)
#  7. Password policy / account-level settings
###############################################################################

# ─── OIDC Provider for GitHub Actions ───────────────────────────────────────

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]

  tags = var.tags
}

# ─── GitHub Actions OIDC Role ───────────────────────────────────────────────

data "aws_iam_policy_document" "github_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.github_oidc_subjects
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.github_actions_role_name
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
  max_session_duration = 3600

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "github_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = var.github_actions_policy_arn
}

# ─── Terraform state bucket ────────────────────────────────────────────────

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.account_id}-terraform-state-${var.aws_region}"

  tags = merge(var.tags, {
    Purpose = "terraform-state"
  })
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── CloudTrail → Central Logging ──────────────────────────────────────────

resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0

  name                       = "${var.team_name}-trail"
  s3_bucket_name             = var.central_logging_bucket
  s3_key_prefix              = var.account_id
  is_multi_region_trail      = true
  enable_log_file_validation = true
  is_organization_trail      = false

  tags = var.tags
}

# ─── IAM Password Policy ───────────────────────────────────────────────────

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
}

# ─── EBS Default Encryption ────────────────────────────────────────────────

resource "aws_ebs_encryption_by_default" "enabled" {
  enabled = true
}

# ─── S3 Account-Level Public Access Block ───────────────────────────────────

resource "aws_s3_account_public_access_block" "block" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
