data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  partition = data.aws_partition.current.partition
}

###############################################################################
# KMS Key for RDS Encryption
###############################################################################
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption - ${var.name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

###############################################################################
# Security Group
###############################################################################
resource "aws_security_group" "rds" {
  name_prefix = "${var.name}-rds-"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_ingress" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.rds.id
  description              = "Allow access from ${each.value}"
}

###############################################################################
# RDS Parameter Group
###############################################################################
resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.name}-"
  family      = "${var.engine}${split(".", var.engine_version)[0]}"
  description = "Parameter group for ${var.name}"

  # Production-grade parameters
  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_checkpoints"
    value = "1"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
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

resource "aws_secretsmanager_secret" "rds" {
  name_prefix = "${var.name}-rds-master-"
  description = "Master password for RDS ${var.name}"
  kms_key_id  = aws_kms_key.rds.arn

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    engine   = var.engine
    host     = aws_db_instance.this.address
    port     = var.port
    dbname   = var.database_name
  })
}

###############################################################################
# Enhanced Monitoring IAM Role
###############################################################################
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

###############################################################################
# RDS Instance
###############################################################################
resource "aws_db_instance" "this" {
  identifier = var.name

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result
  port     = var.port

  multi_az               = var.multi_az
  db_subnet_group_name   = var.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  copy_tags_to_snapshot   = var.copy_tags_to_snapshot
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"

  # Protection
  deletion_protection = var.deletion_protection

  # Monitoring
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = var.performance_insights_retention_period
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports

  # Upgrades
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = false
  apply_immediately           = false

  tags = merge(local.common_tags, {
    Name = var.name
  })
}

###############################################################################
# CloudWatch Alarms
###############################################################################
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${var.name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization is above 80% for 15 minutes"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "free_storage" {
  alarm_name          = "${var.name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB in bytes
  alarm_description   = "RDS free storage is below 10 GB"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "connections" {
  alarm_name          = "${var.name}-rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 200
  alarm_description   = "RDS connection count is above 200 for 15 minutes"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }

  tags = local.common_tags
}
