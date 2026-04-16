locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

###############################################################################
# Security Group
###############################################################################
resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  description = "Security group for ${var.name} ALB"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name}-alb-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "HTTP"
}

resource "aws_security_group_rule" "alb_https" {
  count = var.certificate_arn != "" ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS"
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all egress"
}

###############################################################################
# Application Load Balancer
###############################################################################
resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = var.drop_invalid_header_fields

  dynamic "access_logs" {
    for_each = var.enable_access_logs && var.access_logs_bucket != "" ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(local.common_tags, { Name = var.name })
}

###############################################################################
# Target Groups
###############################################################################
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name                 = "${var.name}-${each.key}"
  port                 = each.value.port
  protocol             = each.value.protocol
  target_type          = each.value.target_type
  vpc_id               = var.vpc_id
  deregistration_delay = each.value.deregistration_delay

  health_check {
    enabled             = each.value.health_check.enabled
    path                = each.value.health_check.path
    port                = each.value.health_check.port
    protocol            = each.value.health_check.protocol
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    interval            = each.value.health_check.interval
    timeout             = each.value.health_check.timeout
    matcher             = each.value.health_check.matcher
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness.enabled ? [1] : []
    content {
      type            = each.value.stickiness.type
      cookie_duration = each.value.stickiness.cookie_duration
      enabled         = true
    }
  }

  tags = merge(local.common_tags, { Name = "${var.name}-${each.key}" })

  lifecycle { create_before_destroy = true }
}

###############################################################################
# Listeners
###############################################################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != "" ? "redirect" : "fixed-response"

    dynamic "redirect" {
      for_each = var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "fixed_response" {
      for_each = var.certificate_arn == "" ? [1] : []
      content {
        content_type = "text/plain"
        message_body = "OK"
        status_code  = "200"
      }
    }
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "https" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = local.common_tags
}
