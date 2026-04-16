data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "data-access"
  })

  partition = data.aws_partition.current.partition

  # Permission maps by resource type and access level
  s3_permissions = {
    readonly  = ["s3:GetObject", "s3:ListBucket", "s3:GetBucketLocation"]
    readwrite = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket", "s3:GetBucketLocation"]
    admin     = ["s3:*"]
  }

  rds_permissions = {
    readonly  = ["rds:DescribeDBInstances", "rds:DescribeDBClusters", "rds-db:connect"]
    readwrite = ["rds:DescribeDBInstances", "rds:DescribeDBClusters", "rds-db:connect"]
    admin     = ["rds:*"]
  }

  dynamodb_permissions = {
    readonly  = ["dynamodb:GetItem", "dynamodb:BatchGetItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:DescribeTable"]
    readwrite = ["dynamodb:GetItem", "dynamodb:BatchGetItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
    admin     = ["dynamodb:*"]
  }

  glue_permissions = {
    readonly  = ["glue:GetDatabase*", "glue:GetTable*", "glue:GetPartition*"]
    readwrite = ["glue:GetDatabase*", "glue:GetTable*", "glue:GetPartition*", "glue:CreateTable", "glue:UpdateTable", "glue:CreatePartition", "glue:BatchCreatePartition"]
    admin     = ["glue:*"]
  }

  permission_map = {
    s3        = local.s3_permissions
    rds       = local.rds_permissions
    dynamodb  = local.dynamodb_permissions
    msk       = { readonly = ["kafka:DescribeCluster*", "kafka:GetBootstrapBrokers", "kafka:ListTopics"], readwrite = ["kafka:*Topic*", "kafka:*Group*", "kafka:DescribeCluster*", "kafka:GetBootstrapBrokers"], admin = ["kafka:*"] }
    documentdb = { readonly = ["rds:DescribeDBClusters", "rds-db:connect"], readwrite = ["rds:DescribeDBClusters", "rds-db:connect"], admin = ["rds:*"] }
    glue      = local.glue_permissions
    redshift  = { readonly = ["redshift:DescribeClusters", "redshift:GetClusterCredentials"], readwrite = ["redshift:DescribeClusters", "redshift:GetClusterCredentials", "redshift:ModifyCluster"], admin = ["redshift:*"] }
  }

  actions = try(local.permission_map[var.target_resource_type][var.access_level], [])
}

###############################################################################
# IAM Role for Data Access
###############################################################################
resource "aws_iam_role" "data_access" {
  name = "${var.environment}-${var.access_name}-data-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Allow specified principals
      [for arn in var.principal_arns : {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { AWS = arn }
      }],
      # Cross-account trust if enabled
      var.enable_cross_account ? [{
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { AWS = var.principal_arns }
        Condition = {
          StringEquals = { "sts:ExternalId" = var.access_name }
        }
      }] : []
    )
  })

  max_session_duration = 3600
  tags                 = local.common_tags
}

###############################################################################
# IAM Policy
###############################################################################
resource "aws_iam_policy" "data_access" {
  name        = "${var.environment}-${var.access_name}-data-access"
  description = "Data access policy for ${var.access_name} (${var.access_level} on ${var.target_resource_type})"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DataAccess"
        Effect   = "Allow"
        Action   = local.actions
        Resource = [var.target_resource_arn, "${var.target_resource_arn}/*"]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "data_access" {
  role       = aws_iam_role.data_access.name
  policy_arn = aws_iam_policy.data_access.arn
}
