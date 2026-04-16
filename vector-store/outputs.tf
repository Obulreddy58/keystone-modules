output "endpoint" {
  description = "Vector store endpoint"
  value       = local.is_pgvector ? (length(aws_db_instance.pgvector) > 0 ? aws_db_instance.pgvector[0].address : "") : (length(aws_opensearchserverless_collection.vector) > 0 ? aws_opensearchserverless_collection.vector[0].collection_endpoint : "")
}

output "store_arn" {
  description = "Vector store ARN"
  value       = local.is_pgvector ? (length(aws_db_instance.pgvector) > 0 ? aws_db_instance.pgvector[0].arn : "") : (length(aws_opensearchserverless_collection.vector) > 0 ? aws_opensearchserverless_collection.vector[0].arn : "")
}

output "secret_arn" {
  description = "Credentials secret ARN (pgvector only)"
  value       = local.is_pgvector && length(aws_secretsmanager_secret.pgvector) > 0 ? aws_secretsmanager_secret.pgvector[0].arn : ""
}

output "security_group_id" {
  description = "Security group ID (pgvector only)"
  value       = local.is_pgvector && length(aws_security_group.vector) > 0 ? aws_security_group.vector[0].id : ""
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.vector.arn
}

output "engine" {
  description = "Vector database engine"
  value       = var.engine
}
