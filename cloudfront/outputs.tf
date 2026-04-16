output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "Route53 hosted zone ID for the distribution"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "oac_id" {
  description = "Origin Access Control ID (for S3 bucket policy)"
  value       = length(aws_cloudfront_origin_access_control.this) > 0 ? aws_cloudfront_origin_access_control.this[0].id : null
}
