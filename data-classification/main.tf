data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "data-classification"
  })

  schedule_map = {
    daily   = "rate(1 day)"
    weekly  = "rate(7 days)"
    monthly = "rate(30 days)"
  }
}

###############################################################################
# Macie Account (enable if not already)
###############################################################################
resource "aws_macie2_account" "this" {
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

###############################################################################
# SNS Topic for Findings
###############################################################################
resource "aws_sns_topic" "classification_findings" {
  name = "${var.environment}-${var.classification_name}-findings"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.classification_findings.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_sns_topic_policy" "macie_publish" {
  arn = aws_sns_topic.classification_findings.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "MaciePublish"
      Effect    = "Allow"
      Principal = { Service = "macie.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.classification_findings.arn
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
      }
    }]
  })
}

###############################################################################
# Macie Classification Job
###############################################################################
resource "aws_macie2_classification_job" "this" {
  name     = "${var.environment}-${var.classification_name}"
  job_type = "SCHEDULED"

  schedule_frequency_and_day {
    value = local.schedule_map[var.schedule_frequency]
  }

  s3_job_definition {
    dynamic "bucket_definitions" {
      for_each = var.target_bucket_arns
      content {
        account_id = data.aws_caller_identity.current.account_id
        buckets    = [split(":::", bucket_definitions.value)[1]]
      }
    }
  }

  custom_data_identifier_ids = var.enable_pii_detection ? [] : []

  tags = local.common_tags

  depends_on = [aws_macie2_account.this]
}

###############################################################################
# Macie Findings EventBridge → SNS
###############################################################################
resource "aws_cloudwatch_event_rule" "macie_findings" {
  name        = "${var.environment}-${var.classification_name}-findings"
  description = "Route Macie findings to SNS"

  event_pattern = jsonencode({
    source      = ["aws.macie"]
    detail-type = ["Macie Finding"]
    detail = {
      classificationDetails = {
        jobId = [aws_macie2_classification_job.this.id]
      }
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "macie_to_sns" {
  rule      = aws_cloudwatch_event_rule.macie_findings.name
  target_id = "macie-findings-sns"
  arn       = aws_sns_topic.classification_findings.arn
}

###############################################################################
# Sensitivity Tags (via AWS tags on buckets)
###############################################################################
resource "aws_s3_bucket_tag" "sensitivity" {
  for_each = toset(var.target_bucket_arns)
  bucket   = split(":::", each.value)[1]
  key      = "DataClassification"
  value    = var.sensitivity_level
}
