output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.this[*].id
}

output "private_ips" {
  description = "List of private IPs"
  value       = aws_instance.this[*].private_ip
}

output "public_ips" {
  description = "List of public IPs (empty if no public IP)"
  value       = aws_instance.this[*].public_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.this.id
}

output "iam_role_name" {
  description = "IAM role name (attach additional policies)"
  value       = aws_iam_role.instance.name
}

output "iam_role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.instance.arn
}
