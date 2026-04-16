output "cluster_arn" {
  description = "MSK cluster ARN"
  value       = aws_msk_cluster.this.arn
}

output "cluster_name" {
  description = "MSK cluster name"
  value       = aws_msk_cluster.this.cluster_name
}

output "bootstrap_brokers_tls" {
  description = "TLS bootstrap brokers connection string"
  value       = aws_msk_cluster.this.bootstrap_brokers_tls
}

output "bootstrap_brokers_iam" {
  description = "IAM bootstrap brokers connection string"
  value       = aws_msk_cluster.this.bootstrap_brokers_sasl_iam
}

output "zookeeper_connect_string" {
  description = "ZooKeeper connection string"
  value       = aws_msk_cluster.this.zookeeper_connect_string
}

output "security_group_id" {
  description = "MSK security group ID"
  value       = aws_security_group.msk.id
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption"
  value       = aws_kms_key.msk.arn
}
