output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "service_names" {
  description = "Map of service names"
  value       = { for k, v in aws_ecs_service.this : k => v.name }
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = aws_iam_role.task.arn
}

output "task_role_name" {
  description = "Name of the task role (attach additional policies to this)"
  value       = aws_iam_role.task.name
}

output "security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs.id
}
