locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

###############################################################################
# HTTP API (API Gateway v2)
###############################################################################
resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  description   = var.description
  protocol_type = var.protocol_type

  dynamic "cors_configuration" {
    for_each = var.cors_configuration != null ? [var.cors_configuration] : []
    content {
      allow_origins     = cors_configuration.value.allow_origins
      allow_methods     = cors_configuration.value.allow_methods
      allow_headers     = cors_configuration.value.allow_headers
      expose_headers    = cors_configuration.value.expose_headers
      max_age           = cors_configuration.value.max_age
      allow_credentials = cors_configuration.value.allow_credentials
    }
  }

  tags = merge(local.common_tags, { Name = var.name })
}

###############################################################################
# Stage with access logging
###############################################################################
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${var.name}"
  retention_in_days = var.access_log_retention_days
  tags              = local.common_tags
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = var.auto_deploy

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn

    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }

  tags = local.common_tags
}

###############################################################################
# Custom Domain
###############################################################################
resource "aws_apigatewayv2_domain_name" "this" {
  count = var.domain_name != "" ? 1 : 0

  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = var.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = local.common_tags
}

resource "aws_apigatewayv2_api_mapping" "this" {
  count = var.domain_name != "" ? 1 : 0

  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.this[0].id
  stage       = aws_apigatewayv2_stage.this.id
}
