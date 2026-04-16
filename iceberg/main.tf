data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "iceberg-datalake"
  })
}

###############################################################################
# KMS Key for Data Lake Encryption
###############################################################################
resource "aws_kms_key" "datalake" {
  description             = "KMS key for Iceberg data lake - ${var.database_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "datalake" {
  name          = "alias/${var.environment}-${var.database_name}-datalake"
  target_key_id = aws_kms_key.datalake.key_id
}

###############################################################################
# S3 Bucket for Data Lake Storage
###############################################################################
resource "aws_s3_bucket" "datalake" {
  count  = var.s3_bucket_name == "" ? 1 : 0
  bucket = "${var.environment}-${var.database_name}-iceberg-${data.aws_caller_identity.current.account_id}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "datalake" {
  count  = var.s3_bucket_name == "" ? 1 : 0
  bucket = aws_s3_bucket.datalake[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datalake" {
  count  = var.s3_bucket_name == "" ? 1 : 0
  bucket = aws_s3_bucket.datalake[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.datalake.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "datalake" {
  count                   = var.s3_bucket_name == "" ? 1 : 0
  bucket                  = aws_s3_bucket.datalake[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  count  = var.s3_bucket_name == "" ? 1 : 0
  bucket = aws_s3_bucket.datalake[0].id

  rule {
    id     = "archive-old-data"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

###############################################################################
# Glue Database
###############################################################################
resource "aws_glue_catalog_database" "this" {
  name         = var.database_name
  catalog_id   = var.catalog_id != "" ? var.catalog_id : data.aws_caller_identity.current.account_id
  description  = "Iceberg data lake database - ${var.database_name}"
  location_uri = "s3://${local.bucket_name}/${var.database_name}/"

  tags = local.common_tags
}

###############################################################################
# Glue Iceberg Table
###############################################################################
resource "aws_glue_catalog_table" "iceberg" {
  database_name = aws_glue_catalog_database.this.name
  name          = var.table_name
  catalog_id    = var.catalog_id != "" ? var.catalog_id : data.aws_caller_identity.current.account_id
  table_type    = "EXTERNAL_TABLE"

  open_table_format_input {
    iceberg_input {
      metadata_operation = "CREATE"
      version            = "2"
    }
  }

  storage_descriptor {
    location      = "s3://${local.bucket_name}/${var.database_name}/${var.table_name}/"
    input_format  = "org.apache.iceberg.mr.hive.HiveIcebergInputFormat"
    output_format = "org.apache.iceberg.mr.hive.HiveIcebergOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.iceberg.mr.hive.HiveIcebergSerDe"
    }
  }

  parameters = {
    "table_type"          = "ICEBERG"
    "format"              = var.file_format
    "write.format.default" = var.file_format
    "write.parquet.compression-codec" = var.compression
  }
}

###############################################################################
# IAM Role for Glue access
###############################################################################
resource "aws_iam_role" "glue_service" {
  name = "${var.environment}-${var.database_name}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "glue_s3_access" {
  name = "${var.environment}-${var.database_name}-glue-s3"
  role = aws_iam_role.glue_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
          "s3:ListBucket", "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_name}",
          "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_name}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
        Resource = [aws_kms_key.datalake.arn]
      }
    ]
  })
}

###############################################################################
# Locals
###############################################################################
locals {
  bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : (
    length(aws_s3_bucket.datalake) > 0 ? aws_s3_bucket.datalake[0].id : ""
  )
}
