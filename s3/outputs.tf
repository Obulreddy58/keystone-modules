output "bucket_id" {
  description = "Bucket name"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "Bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name (for CloudFront origin)"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "kms_key_arn" {
  description = "KMS key ARN (null if AES256)"
  value       = length(aws_kms_key.this) > 0 ? aws_kms_key.this[0].arn : null
}
