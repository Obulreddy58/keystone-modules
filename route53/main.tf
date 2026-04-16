locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  is_private = length(var.vpc_associations) > 0
}

###############################################################################
# Hosted Zone
###############################################################################
resource "aws_route53_zone" "this" {
  name          = var.domain_name
  comment       = var.comment != "" ? var.comment : "${var.domain_name} - ${var.environment}"
  force_destroy = var.force_destroy

  delegation_set_id = local.is_private ? null : var.delegation_set_id

  dynamic "vpc" {
    for_each = var.vpc_associations
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  tags = merge(local.common_tags, { Name = var.domain_name })
}

###############################################################################
# DNS Records
###############################################################################
resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = aws_route53_zone.this.zone_id
  name    = each.key
  type    = each.value.type

  # Simple records (non-alias)
  ttl     = each.value.alias == null ? each.value.ttl : null
  records = each.value.alias == null ? each.value.records : null

  # Alias records
  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  health_check_id = each.value.health_check_id
  set_identifier  = each.value.set_identifier

  dynamic "weighted_routing_policy" {
    for_each = each.value.weighted_routing_policy != null ? [each.value.weighted_routing_policy] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  dynamic "latency_routing_policy" {
    for_each = each.value.latency_routing_policy != null ? [each.value.latency_routing_policy] : []
    content {
      region = latency_routing_policy.value.region
    }
  }

  dynamic "failover_routing_policy" {
    for_each = each.value.failover_routing_policy != null ? [each.value.failover_routing_policy] : []
    content {
      type = failover_routing_policy.value.type
    }
  }
}

###############################################################################
# Health Checks
###############################################################################
resource "aws_route53_health_check" "this" {
  for_each = var.health_checks

  type                            = each.value.type
  fqdn                            = each.value.fqdn
  ip_address                      = each.value.ip_address
  port                            = each.value.port
  resource_path                   = contains(["HTTP", "HTTPS"], each.value.type) ? each.value.resource_path : null
  failure_threshold               = each.value.failure_threshold
  request_interval                = each.value.request_interval
  search_string                   = each.value.search_string
  measure_latency                 = each.value.measure_latency
  regions                         = each.value.regions
  enable_sni                      = each.value.type == "HTTPS" ? each.value.enable_sni : null
  cloudwatch_alarm_name           = each.value.cloudwatch_alarm_name
  cloudwatch_alarm_region         = each.value.cloudwatch_alarm_region
  insufficient_data_health_status = each.value.insufficient_data_health_status

  tags = merge(local.common_tags, { Name = "${var.domain_name}-${each.key}" })
}

###############################################################################
# DNSSEC
###############################################################################
resource "aws_route53_hosted_zone_dnssec" "this" {
  count = var.enable_dnssec && !local.is_private ? 1 : 0

  hosted_zone_id = aws_route53_zone.this.zone_id
}
