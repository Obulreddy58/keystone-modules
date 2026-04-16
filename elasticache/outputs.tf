output "replication_group_id" {
  description = "The ElastiCache replication group ID"
  value       = aws_elasticache_replication_group.this.id
}

output "replication_group_arn" {
  description = "The ElastiCache replication group ARN"
  value       = aws_elasticache_replication_group.this.arn
}

output "primary_endpoint_address" {
  description = "Primary endpoint address"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.this.port
}

output "security_group_id" {
  description = "Security group ID for the Redis cluster"
  value       = aws_security_group.redis.id
}

output "connection_string" {
  description = "Redis connection string (TLS)"
  value       = "rediss://${aws_elasticache_replication_group.this.primary_endpoint_address}:${aws_elasticache_replication_group.this.port}"
}
