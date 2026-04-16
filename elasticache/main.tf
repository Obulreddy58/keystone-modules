locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

###############################################################################
# Subnet Group
###############################################################################
resource "aws_elasticache_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, { Name = var.name })
}

###############################################################################
# Parameter Group
###############################################################################
resource "aws_elasticache_parameter_group" "this" {
  name   = var.name
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(local.common_tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# Security Group
###############################################################################
resource "aws_security_group" "redis" {
  name_prefix = "${var.name}-redis-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name}-redis" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_sg" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.redis.id
  description                  = "Redis from allowed security group"
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_cidr" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.redis.id
  description       = "Redis from CIDR"
  from_port         = var.port
  to_port           = var.port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "redis_all" {
  security_group_id = aws_security_group.redis.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

###############################################################################
# Replication Group (Redis Cluster)
###############################################################################
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.name
  description          = "${var.name} Redis cluster"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters
  port                 = var.port

  parameter_group_name = aws_elasticache_parameter_group.this.name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.redis.id]

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  transit_encryption_mode    = var.transit_encryption_enabled ? var.transit_encryption_mode : null
  kms_key_id                 = var.kms_key_arn
  auth_token                 = var.auth_token

  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window
  maintenance_window       = var.maintenance_window

  notification_topic_arn     = var.notification_topic_arn
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  dynamic "log_delivery_configuration" {
    for_each = var.log_delivery_configuration
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  tags = merge(local.common_tags, { Name = var.name })
}
