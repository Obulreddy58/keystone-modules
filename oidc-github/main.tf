data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id

  # Build the subject conditions for branch-based access
  oidc_subjects = [
    for branch in var.allowed_branches :
    "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
  ]

  # Also allow pull_request events for plan
  oidc_subjects_like = [
    "repo:${var.github_org}/${var.github_repo}:pull_request",
    "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/*",
  ]
}

###############################################################################
# GitHub OIDC Provider (only one per account, idempotent)
###############################################################################
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_thumbprint]

  tags = merge(local.common_tags, {
    Name = "github-actions-oidc"
  })
}

###############################################################################
# Deploy IAM Role (assumed by GitHub Actions via OIDC)
###############################################################################
resource "aws_iam_role" "deploy" {
  name                 = "${var.name}-deploy"
  max_session_duration = var.max_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.oidc_subjects_like
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.name}-deploy"
  })
}

###############################################################################
# Default policy — broad enough for VPC, EKS, RDS, KMS, IAM, etc.
###############################################################################
resource "aws_iam_role_policy" "deploy_default" {
  count = var.create_default_policy ? 1 : 0

  name = "${var.name}-deploy-policy"
  role = aws_iam_role.deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Terraform"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "eks:*",
          "rds:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "iam:*",
          "kms:*",
          "logs:*",
          "cloudwatch:*",
          "s3:*",
          "dynamodb:*",
          "secretsmanager:*",
          "ssm:*",
          "sts:*",
        ]
        Resource = "*"
      }
    ]
  })
}

###############################################################################
# Attach additional managed policies
###############################################################################
resource "aws_iam_role_policy_attachment" "deploy" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.deploy.name
  policy_arn = each.value
}
