output "table_name" {
  description = "The DynamoDB table name"
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "The DynamoDB table ARN"
  value       = aws_dynamodb_table.this.arn
}

output "table_id" {
  description = "The DynamoDB table ID"
  value       = aws_dynamodb_table.this.id
}

output "table_stream_arn" {
  description = "The DynamoDB table stream ARN (if streams enabled)"
  value       = aws_dynamodb_table.this.stream_arn
}

output "table_stream_label" {
  description = "The DynamoDB table stream label (if streams enabled)"
  value       = aws_dynamodb_table.this.stream_label
}
