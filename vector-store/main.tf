data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "vector-store"
  })

  is_pgvector = var.engine == "pgvector"
}

###############################################################################
# KMS Key
###############################################################################
resource "aws_kms_key" "vector" {
  description             = "KMS key for vector store - ${var.name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "vector" {
  name          = "alias/${var.environment}-${var.name}-vector"
  target_key_id = aws_kms_key.vector.key_id
}

resource "aws_kms_key_policy" "vector" {
  key_id = aws_kms_key.vector.id

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
resource "aws_security_group" "vector" {
  count       = local.is_pgvector ? 1 : 0
  name        = "${var.environment}-${var.name}-vector-sg"
  description = "Security group for vector store ${var.name}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(local.common_tags, { Name = "${var.environment}-${var.name}-vector-sg" })
}

resource "aws_security_group_rule" "vector_ingress" {
  for_each                 = local.is_pgvector ? toset(var.allowed_security_group_ids) : toset([])
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.vector[0].id
  description              = "PostgreSQL from ${each.value}"
}

###############################################################################
# Option A: RDS PostgreSQL with pgvector
###############################################################################
resource "aws_db_subnet_group" "pgvector" {
  count      = local.is_pgvector ? 1 : 0
  name       = "${var.environment}-${var.name}-pgvector"
  subnet_ids = var.database_subnet_ids
  tags       = local.common_tags
}

resource "random_password" "pgvector" {
  count   = local.is_pgvector ? 1 : 0
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "pgvector" {
  count       = local.is_pgvector ? 1 : 0
  name        = "${var.environment}-${var.name}-pgvector-credentials"
  description = "Credentials for pgvector store ${var.name}"
  kms_key_id  = aws_kms_key.vector.arn
  tags        = local.common_tags
}

resource "aws_secretsmanager_secret_version" "pgvector" {
  count     = local.is_pgvector ? 1 : 0
  secret_id = aws_secretsmanager_secret.pgvector[0].id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.pgvector[0].result
    host     = aws_db_instance.pgvector[0].address
    port     = 5432
    dbname   = var.name
  })
}

resource "aws_db_parameter_group" "pgvector" {
  count  = local.is_pgvector ? 1 : 0
  name   = "${var.environment}-${var.name}-pgvector"
  family = "postgres16"

  parameter {
    name  = "shared_preload_libraries"
    value = "pgvector"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = local.common_tags
}

resource "aws_db_instance" "pgvector" {
  count                      = local.is_pgvector ? 1 : 0
  identifier                 = "${var.environment}-${var.name}-pgvector"
  engine                     = "postgres"
  engine_version             = "16.4"
  instance_class             = var.instance_class
  allocated_storage          = 100
  max_allocated_storage      = 1000
  db_name                    = replace(var.name, "-", "_")
  username                   = var.master_username
  password                   = random_password.pgvector[0].result
  db_subnet_group_name       = aws_db_subnet_group.pgvector[0].name
  vpc_security_group_ids     = [aws_security_group.vector[0].id]
  parameter_group_name       = aws_db_parameter_group.pgvector[0].name
  storage_encrypted          = true
  kms_key_id                 = aws_kms_key.vector.arn
  multi_az                   = var.environment == "prod"
  deletion_protection        = var.deletion_protection
  backup_retention_period    = 30
  backup_window              = "03:00-04:00"
  maintenance_window         = "sun:05:00-sun:06:00"
  performance_insights_enabled          = true
  performance_insights_retention_period = 731
  skip_final_snapshot        = var.environment != "prod"
  final_snapshot_identifier  = var.environment == "prod" ? "${var.name}-final-snapshot" : null
  tags                       = local.common_tags
}

###############################################################################
# Option B: OpenSearch Serverless Collection
###############################################################################
resource "aws_opensearchserverless_security_policy" "encryption" {
  count = local.is_pgvector ? 0 : 1
  name  = "${var.name}-enc"
  type  = "encryption"
  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.name}"]
    }]
    AWSOwnedKey = false
    KmsARN      = aws_kms_key.vector.arn
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  count = local.is_pgvector ? 0 : 1
  name  = "${var.name}-net"
  type  = "network"
  policy = jsonencode([{
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.name}"]
    }]
    AllowFromPublic = false
  }])
}

resource "aws_opensearchserverless_collection" "vector" {
  count = local.is_pgvector ? 0 : 1
  name  = var.name
  type  = "VECTORSEARCH"
  tags  = local.common_tags

  depends_on = [
    aws_opensearchserverless_security_policy.encryption[0],
    aws_opensearchserverless_security_policy.network[0],
  ]
}
