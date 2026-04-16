output "zone_id" {
  description = "The hosted zone ID"
  value       = aws_route53_zone.this.zone_id
}

output "zone_arn" {
  description = "The hosted zone ARN"
  value       = aws_route53_zone.this.arn
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = aws_route53_zone.this.name_servers
}

output "domain_name" {
  description = "The domain name of the hosted zone"
  value       = aws_route53_zone.this.name
}

output "health_check_ids" {
  description = "Map of health check name to ID"
  value       = { for k, v in aws_route53_health_check.this : k => v.id }
}

output "record_fqdns" {
  description = "Map of record name to FQDN"
  value       = { for k, v in aws_route53_record.this : k => v.fqdn }
}
