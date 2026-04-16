output "share_arn" {
  description = "RAM resource share ARN"
  value       = aws_ram_resource_share.this.arn
}

output "share_id" {
  description = "RAM resource share ID"
  value       = aws_ram_resource_share.this.id
}

output "associated_resource_count" {
  description = "Number of associated resources"
  value       = length(aws_ram_resource_association.resources)
}

output "target_accounts" {
  description = "Target account IDs"
  value       = [for a in aws_ram_principal_association.accounts : a.principal]
}

output "permission_type" {
  description = "Granted permission type"
  value       = var.permission_type
}
