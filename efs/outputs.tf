output "file_system_id" {
  description = "The EFS file system ID"
  value       = aws_efs_file_system.this.id
}

output "file_system_arn" {
  description = "The EFS file system ARN"
  value       = aws_efs_file_system.this.arn
}

output "file_system_dns_name" {
  description = "The DNS name of the file system"
  value       = aws_efs_file_system.this.dns_name
}

output "mount_target_ids" {
  description = "Map of subnet ID to mount target ID"
  value       = { for k, v in aws_efs_mount_target.this : k => v.id }
}

output "security_group_id" {
  description = "Security group ID for EFS mount targets"
  value       = aws_security_group.efs.id
}

output "access_point_ids" {
  description = "Map of access point name to ID"
  value       = { for k, v in aws_efs_access_point.this : k => v.id }
}

output "access_point_arns" {
  description = "Map of access point name to ARN"
  value       = { for k, v in aws_efs_access_point.this : k => v.arn }
}
