output "cluster_id" {
  description = "The DocumentDB cluster identifier"
  value       = aws_docdb_cluster.this.id
}

output "cluster_arn" {
  description = "The ARN of the DocumentDB cluster"
  value       = aws_docdb_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The cluster endpoint (primary, read-write)"
  value       = aws_docdb_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "The reader endpoint (load-balanced read replicas)"
  value       = aws_docdb_cluster.this.reader_endpoint
}

output "cluster_port" {
  description = "The DocumentDB port"
  value       = aws_docdb_cluster.this.port
}

output "master_username" {
  description = "The master username"
  value       = aws_docdb_cluster.this.master_username
  sensitive   = true
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing credentials"
  value       = aws_secretsmanager_secret.docdb.arn
}

output "security_group_id" {
  description = "Security group ID of the DocumentDB cluster"
  value       = aws_security_group.docdb.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for DocumentDB encryption"
  value       = aws_kms_key.docdb.arn
}

output "instance_endpoints" {
  description = "List of instance endpoints"
  value       = aws_docdb_cluster_instance.this[*].endpoint
}
