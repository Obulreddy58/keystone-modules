locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  has_s3_origin  = var.s3_origin != null
  has_alb_origin = var.alb_origin != null
}

###############################################################################
# Origin Access Control (for S3 origins)
###############################################################################
resource "aws_cloudfront_origin_access_control" "this" {
  count = local.has_s3_origin ? 1 : 0

  name                              = "${var.name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

###############################################################################
# Response Headers Policy (security headers)
###############################################################################
resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.name}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    content_security_policy {
      content_security_policy = "default-src 'self'"
      override                = false
    }
  }
}

###############################################################################
# CloudFront Distribution
###############################################################################
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.name} distribution"
  default_root_object = var.default_root_object
  price_class         = var.price_class
  aliases             = var.aliases
  web_acl_id          = var.web_acl_id != "" ? var.web_acl_id : null

  # S3 Origin
  dynamic "origin" {
    for_each = local.has_s3_origin ? [var.s3_origin] : []
    content {
      domain_name              = origin.value.bucket_regional_domain_name
      origin_id                = origin.value.origin_id
      origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
    }
  }

  # ALB Origin
  dynamic "origin" {
    for_each = local.has_alb_origin ? [var.alb_origin] : []
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id

      custom_origin_config {
        http_port              = origin.value.http_port
        https_port             = origin.value.https_port
        origin_protocol_policy = origin.value.protocol
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    target_origin_id           = local.has_s3_origin ? var.s3_origin.origin_id : var.alb_origin.origin_id
    allowed_methods            = var.default_cache_behavior.allowed_methods
    cached_methods             = var.default_cache_behavior.cached_methods
    viewer_protocol_policy     = var.default_cache_behavior.viewer_protocol_policy
    compress                   = var.default_cache_behavior.compress
    min_ttl                    = var.default_cache_behavior.min_ttl
    default_ttl                = var.default_cache_behavior.default_ttl
    max_ttl                    = var.default_cache_behavior.max_ttl
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    forwarded_values {
      query_string = local.has_alb_origin
      cookies {
        forward = local.has_alb_origin ? "all" : "none"
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == ""
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != "" ? "TLSv1.2_2021" : "TLSv1"
  }

  dynamic "logging_config" {
    for_each = var.enable_logging && var.logging_bucket != "" ? [1] : []
    content {
      include_cookies = false
      bucket          = var.logging_bucket
      prefix          = var.logging_prefix
    }
  }

  tags = merge(local.common_tags, { Name = var.name })
}
