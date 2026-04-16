locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

###############################################################################
# IP Sets
###############################################################################
resource "aws_wafv2_ip_set" "blocked" {
  count = length(var.blocked_ip_addresses) > 0 ? 1 : 0

  name               = "${var.name}-blocked-ips"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.blocked_ip_addresses

  tags = local.common_tags
}

resource "aws_wafv2_ip_set" "allowed" {
  count = length(var.allowed_ip_addresses) > 0 ? 1 : 0

  name               = "${var.name}-allowed-ips"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.allowed_ip_addresses

  tags = local.common_tags
}

###############################################################################
# WAF Web ACL
###############################################################################
resource "aws_wafv2_web_acl" "this" {
  name  = var.name
  scope = var.scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${replace(var.name, "-", "")}Default"
    sampled_requests_enabled   = true
  }

  # --- Priority 0: Allow-listed IPs ---
  dynamic "rule" {
    for_each = length(var.allowed_ip_addresses) > 0 ? [1] : []
    content {
      name     = "AllowListedIPs"
      priority = 0

      action { allow {} }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allowed[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${replace(var.name, "-", "")}AllowListedIPs"
        sampled_requests_enabled   = true
      }
    }
  }

  # --- Priority 1: Block-listed IPs ---
  dynamic "rule" {
    for_each = length(var.blocked_ip_addresses) > 0 ? [1] : []
    content {
      name     = "BlockListedIPs"
      priority = 1

      action { block {} }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.blocked[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${replace(var.name, "-", "")}BlockListedIPs"
        sampled_requests_enabled   = true
      }
    }
  }

  # --- Priority 2: Rate limiting ---
  rule {
    name     = "RateLimit"
    priority = 2

    action { block {} }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(var.name, "-", "")}RateLimit"
      sampled_requests_enabled   = true
    }
  }

  # --- Priority 10: AWS Managed Common Rule Set ---
  dynamic "rule" {
    for_each = var.enable_aws_managed_rules ? [1] : []
    content {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10

      override_action { none {} }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${replace(var.name, "-", "")}CommonRuleSet"
        sampled_requests_enabled   = true
      }
    }
  }

  # --- Priority 11: SQL Injection ---
  dynamic "rule" {
    for_each = var.enable_sql_injection_rule ? [1] : []
    content {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 11

      override_action { none {} }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesSQLiRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${replace(var.name, "-", "")}SQLiRuleSet"
        sampled_requests_enabled   = true
      }
    }
  }

  # --- Priority 12: XSS ---
  dynamic "rule" {
    for_each = var.enable_xss_rule ? [1] : []
    content {
      name     = "AWSManagedRulesXSSRuleSet"
      priority = 12

      override_action { none {} }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesKnownBadInputsRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${replace(var.name, "-", "")}XSSRuleSet"
        sampled_requests_enabled   = true
      }
    }
  }

  # --- Priority 13: IP Reputation ---
  dynamic "rule" {
    for_each = var.enable_ip_reputation_rule ? [1] : []
    content {
      name     = "AWSManagedRulesAmazonIpReputationList"
      priority = 13

      override_action { none {} }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesAmazonIpReputationList"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${replace(var.name, "-", "")}IpReputation"
        sampled_requests_enabled   = true
      }
    }
  }

  # --- Priority 14: Bot Control ---
  dynamic "rule" {
    for_each = var.enable_bot_control ? [1] : []
    content {
      name     = "AWSManagedRulesBotControlRuleSet"
      priority = 14

      override_action { none {} }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesBotControlRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${replace(var.name, "-", "")}BotControl"
        sampled_requests_enabled   = true
      }
    }
  }

  tags = merge(local.common_tags, { Name = var.name })
}

###############################################################################
# Association with resources (ALB, API Gateway, etc.)
###############################################################################
resource "aws_wafv2_web_acl_association" "this" {
  count = var.scope == "REGIONAL" ? length(var.resource_arns) : 0

  resource_arn = var.resource_arns[count.index]
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

###############################################################################
# Logging
###############################################################################
resource "aws_cloudwatch_log_group" "waf" {
  count = var.enable_logging ? 1 : 0

  # WAF logging requires the log group name to start with aws-waf-logs-
  name              = "aws-waf-logs-${var.name}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.enable_logging ? 1 : 0

  log_destination_configs = [aws_cloudwatch_log_group.waf[0].arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
}
