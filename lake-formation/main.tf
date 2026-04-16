data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "lake-formation"
  })

  catalog_id = var.catalog_id != "" ? var.catalog_id : data.aws_caller_identity.current.account_id
}

###############################################################################
# Lake Formation Settings
###############################################################################
resource "aws_lakeformation_data_lake_settings" "this" {
  admins     = [var.admin_arn]
  catalog_id = local.catalog_id

  create_database_default_permissions {
    permissions = ["ALL"]
    principal   = var.admin_arn
  }

  create_table_default_permissions {
    permissions = ["ALL"]
    principal   = var.admin_arn
  }
}

###############################################################################
# IAM Role for Lake Formation
###############################################################################
resource "aws_iam_role" "lf_service" {
  name = "${var.environment}-${var.data_lake_name}-lf-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lakeformation.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "lf_s3_access" {
  name = "${var.environment}-${var.data_lake_name}-lf-s3"
  role = aws_iam_role.lf_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:GetBucketLocation"]
        Resource = flatten([for arn in var.s3_locations : [arn, "${arn}/*"]])
      },
      {
        Effect   = "Allow"
        Action   = ["glue:*Database*", "glue:*Table*", "glue:*Partition*"]
        Resource = ["*"]
      }
    ]
  })
}

###############################################################################
# Data Lake Location Registration
###############################################################################
resource "aws_lakeformation_resource" "locations" {
  for_each = toset(var.s3_locations)
  arn      = each.value
  role_arn = aws_iam_role.lf_service.arn
}

###############################################################################
# LF-Tags
###############################################################################
resource "aws_lakeformation_lf_tag" "tags" {
  for_each   = var.lf_tags
  catalog_id = local.catalog_id
  key        = each.key
  values     = each.value
}
