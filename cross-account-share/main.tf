data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "cross-account-share"
  })
}

###############################################################################
# RAM Resource Share
###############################################################################
resource "aws_ram_resource_share" "this" {
  name                      = "${var.environment}-${var.share_name}"
  allow_external_principals = var.enable_external_sharing
  tags                      = local.common_tags
}

###############################################################################
# Associate Resources
###############################################################################
resource "aws_ram_resource_association" "resources" {
  for_each           = toset(var.resource_arns)
  resource_share_arn = aws_ram_resource_share.this.arn
  resource_arn       = each.value
}

###############################################################################
# Associate Target Accounts
###############################################################################
resource "aws_ram_principal_association" "accounts" {
  for_each           = toset(var.target_account_ids)
  resource_share_arn = aws_ram_resource_share.this.arn
  principal          = each.value
}

###############################################################################
# KMS Key Grant for Encrypted Resources
###############################################################################
resource "aws_kms_grant" "cross_account" {
  for_each          = var.kms_key_arn != "" ? toset(var.target_account_ids) : toset([])
  name              = "${var.share_name}-${each.value}"
  key_id            = var.kms_key_arn
  grantee_principal = "arn:aws:iam::${each.value}:root"

  operations = var.permission_type == "readonly" ? [
    "Decrypt", "DescribeKey"
  ] : [
    "Decrypt", "Encrypt", "GenerateDataKey", "DescribeKey", "ReEncryptFrom", "ReEncryptTo"
  ]
}
