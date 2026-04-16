data "aws_partition" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
  partition = data.aws_partition.current.partition
  use_s3    = var.s3_bucket != ""
}

###############################################################################
# IAM Execution Role
###############################################################################
resource "aws_iam_role" "lambda" {
  name = "${var.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc" {
  count = var.vpc_config != null ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.lambda.name
  policy_arn = each.value
}

###############################################################################
# CloudWatch Log Group
###############################################################################
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

###############################################################################
# Lambda Function
###############################################################################
resource "aws_lambda_function" "this" {
  function_name = var.name
  description   = var.description
  role          = aws_iam_role.lambda.arn
  handler       = var.handler
  runtime       = var.runtime

  filename         = !local.use_s3 ? var.filename : null
  source_code_hash = !local.use_s3 && var.filename != "" ? filebase64sha256(var.filename) : null
  s3_bucket        = local.use_s3 ? var.s3_bucket : null
  s3_key           = local.use_s3 ? var.s3_key : null

  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  layers                         = var.layers

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != "" ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  tracing_config {
    mode = var.tracing_mode
  }

  tags = merge(local.common_tags, { Name = var.name })

  depends_on = [aws_cloudwatch_log_group.lambda]
}
