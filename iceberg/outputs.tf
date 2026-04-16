output "database_name" {
  description = "Glue database name"
  value       = aws_glue_catalog_database.this.name
}

output "database_arn" {
  description = "Glue database ARN"
  value       = aws_glue_catalog_database.this.arn
}

output "table_name" {
  description = "Iceberg table name"
  value       = aws_glue_catalog_table.iceberg.name
}

output "table_arn" {
  description = "Glue table ARN"
  value       = aws_glue_catalog_table.iceberg.arn
}

output "s3_bucket_name" {
  description = "Data lake S3 bucket name"
  value       = local.bucket_name
}

output "s3_location" {
  description = "Iceberg table S3 location"
  value       = "s3://${local.bucket_name}/${var.database_name}/${var.table_name}/"
}

output "kms_key_arn" {
  description = "KMS key ARN for data encryption"
  value       = aws_kms_key.datalake.arn
}

output "glue_role_arn" {
  description = "IAM role ARN for Glue access"
  value       = aws_iam_role.glue_service.arn
}
