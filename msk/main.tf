data "aws_partition" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
  partition = data.aws_partition.current.partition
}

###############################################################################
# KMS Key
###############################################################################
resource "aws_kms_key" "msk" {
  description             = "KMS key for MSK encryption - ${var.name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "msk" {
  name          = "alias/${var.name}-msk"
  target_key_id = aws_kms_key.msk.key_id
}

###############################################################################
# Security Group
###############################################################################
resource "aws_security_group" "msk" {
  name_prefix = "${var.name}-msk-"
  description = "Security group for MSK cluster"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name}-msk-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "msk_ingress" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = 9092
  to_port                  = 9098
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.msk.id
  description              = "Kafka from ${each.value}"
}

resource "aws_security_group_rule" "msk_zookeeper" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = 2181
  to_port                  = 2181
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.msk.id
  description              = "ZooKeeper from ${each.value}"
}

resource "aws_security_group_rule" "msk_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.msk.id
  description       = "Allow all egress"
}

###############################################################################
# CloudWatch Log Group
###############################################################################
resource "aws_cloudwatch_log_group" "msk" {
  count             = var.cloudwatch_logs_enabled ? 1 : 0
  name              = "/aws/msk/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

###############################################################################
# MSK Configuration
###############################################################################
resource "aws_msk_configuration" "this" {
  name              = "${var.name}-config"
  kafka_versions    = [var.kafka_version]
  server_properties = var.configuration_server_properties
}

###############################################################################
# MSK Cluster
###############################################################################
resource "aws_msk_cluster" "this" {
  cluster_name           = var.name
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes

  broker_node_group_info {
    instance_type  = var.broker_instance_type
    client_subnets = var.subnet_ids
    security_groups = [aws_security_group.msk.id]

    storage_info {
      ebs_storage_info {
        volume_size = var.broker_ebs_volume_size

        provisioned_throughput {
          enabled           = var.broker_ebs_throughput > 0
          volume_throughput = var.broker_ebs_throughput
        }
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.this.arn
    revision = aws_msk_configuration.this.latest_revision
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.msk.arn

    encryption_in_transit {
      client_broker = var.encryption_in_transit
      in_cluster    = true
    }
  }

  dynamic "client_authentication" {
    for_each = var.client_authentication == "iam" ? [1] : []
    content {
      sasl {
        iam = true
      }
    }
  }

  dynamic "client_authentication" {
    for_each = var.client_authentication == "sasl_scram" ? [1] : []
    content {
      sasl {
        scram = true
      }
    }
  }

  dynamic "client_authentication" {
    for_each = var.client_authentication == "tls" ? [1] : []
    content {
      tls {}
    }
  }

  enhanced_monitoring = var.enhanced_monitoring

  logging_info {
    broker_logs {
      dynamic "cloudwatch_logs" {
        for_each = var.cloudwatch_logs_enabled ? [1] : []
        content {
          enabled   = true
          log_group = aws_cloudwatch_log_group.msk[0].name
        }
      }
    }
  }

  tags = merge(local.common_tags, { Name = var.name })
}

###############################################################################
# Storage Auto Scaling
###############################################################################
resource "aws_appautoscaling_target" "msk_storage" {
  count = var.auto_scaling_max_storage > 0 ? 1 : 0

  max_capacity       = var.auto_scaling_max_storage
  min_capacity       = var.broker_ebs_volume_size
  resource_id        = aws_msk_cluster.this.arn
  scalable_dimension = "kafka:broker-storage:VolumeSize"
  service_namespace  = "kafka"
}

resource "aws_appautoscaling_policy" "msk_storage" {
  count = var.auto_scaling_max_storage > 0 ? 1 : 0

  name               = "${var.name}-msk-storage-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.msk_storage[0].resource_id
  scalable_dimension = aws_appautoscaling_target.msk_storage[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.msk_storage[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "KafkaBrokerStorageUtilization"
    }
    target_value = 70
  }
}
