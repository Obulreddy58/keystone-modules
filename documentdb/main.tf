data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "documentdb"
  })

  partition = data.aws_partition.current.partition
}

###############################################################################
# KMS Key for DocumentDB Encryption
###############################################################################
resource "aws_kms_key" "docdb" {
  description             = "KMS key for DocumentDB encryption - ${var.name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "docdb" {
  name          = "alias/${var.name}-docdb"
  target_key_id = aws_kms_key.docdb.key_id
}

resource "aws_kms_key_policy" "docdb" {
  key_id = aws_kms_key.docdb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowRDS"
        Effect    = "Allow"
        Principal = { Service = "rds.amazonaws.com" }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid       = "AllowSecretsManager"
        Effect    = "Allow"
        Principal = { Service = "secretsmanager.amazonaws.com" }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })
}

###############################################################################
# Security Group
###############################################################################
resource "aws_security_group" "docdb" {
  name_prefix = "${var.name}-docdb-"
  description = "Security group for DocumentDB cluster"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name}-docdb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "docdb_ingress" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.docdb.id
  description              = "Allow access from ${each.value}"
}

###############################################################################
# DocumentDB Subnet Group
###############################################################################
resource "aws_docdb_subnet_group" "this" {
  name       = "${var.name}-docdb"
  subnet_ids = var.database_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.name}-docdb-subnet-group"
  })
}

###############################################################################
# DocumentDB Cluster Parameter Group
###############################################################################
resource "aws_docdb_cluster_parameter_group" "this" {
  family      = "docdb${var.engine_version}"
  name_prefix = "${var.name}-"
  description = "Cluster parameter group for ${var.name}"

  # Enforce TLS connections
  parameter {
    name  = "tls"
    value = "enabled"
  }

  # Enable audit logging
  parameter {
    name  = "audit_logs"
    value = "enabled"
  }

  # Enable profiler for slow queries
  parameter {
    name  = "profiler"
    value = "enabled"
  }

  parameter {
    name  = "profiler_threshold_ms"
    value = "100"
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# Master Password via Secrets Manager
###############################################################################
resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}|:,.<>?"
}

resource "aws_secretsmanager_secret" "docdb" {
  name_prefix = "${var.name}-docdb-master-"
  description = "Master password for DocumentDB ${var.name}"
  kms_key_id  = aws_kms_key.docdb.arn

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "docdb" {
  secret_id = aws_secretsmanager_secret.docdb.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    engine   = "docdb"
    host     = aws_docdb_cluster.this.endpoint
    port     = var.port
    ssl      = true
  })
}

###############################################################################
# DocumentDB Cluster
###############################################################################
resource "aws_docdb_cluster" "this" {
  cluster_identifier = var.name

  engine         = "docdb"
  engine_version = var.engine_version

  master_username = var.master_username
  master_password = random_password.master.result

  port = var.port

  db_subnet_group_name            = aws_docdb_subnet_group.this.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.this.name
  vpc_security_group_ids          = [aws_security_group.docdb.id]

  # Encryption
  storage_encrypted = true
  kms_key_id        = aws_kms_key.docdb.arn

  # Backup
  backup_retention_period   = var.backup_retention_period
  preferred_backup_window   = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"

  # Protection
  deletion_protection = var.deletion_protection

  # Logging
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]

  tags = merge(local.common_tags, {
    Name = var.name
  })
}

###############################################################################
# DocumentDB Cluster Instances
###############################################################################
resource "aws_docdb_cluster_instance" "this" {
  count = var.num_instances

  identifier         = "${var.name}-${count.index}"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = var.instance_class

  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  tags = merge(local.common_tags, {
    Name = "${var.name}-${count.index}"
  })
}

###############################################################################
# CloudWatch Alarms
###############################################################################
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${var.name}-docdb-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "DocumentDB CPU utilization is above 80% for 15 minutes"

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.this.cluster_identifier
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "free_memory" {
  alarm_name          = "${var.name}-docdb-low-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "FreeableMemory"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = 1073741824 # 1 GB in bytes
  alarm_description   = "DocumentDB freeable memory is below 1 GB for 15 minutes"

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.this.cluster_identifier
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "connections" {
  alarm_name          = "${var.name}-docdb-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = 500
  alarm_description   = "DocumentDB connection count is above 500 for 15 minutes"

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.this.cluster_identifier
  }

  tags = local.common_tags
}
