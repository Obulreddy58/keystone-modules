output "role_arn" {
  description = "Data access IAM role ARN"
  value       = aws_iam_role.data_access.arn
}

output "role_name" {
  description = "Data access IAM role name"
  value       = aws_iam_role.data_access.name
}

output "policy_arn" {
  description = "Data access IAM policy ARN"
  value       = aws_iam_policy.data_access.arn
}

output "access_level" {
  description = "Granted access level"
  value       = var.access_level
}

output "target_resource_type" {
  description = "Target resource type"
  value       = var.target_resource_type
}
