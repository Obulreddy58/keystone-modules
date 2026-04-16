output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "deploy_role_arn" {
  description = "ARN of the deploy IAM role (set this as AWS_ROLE_ARN secret in GitHub)"
  value       = aws_iam_role.deploy.arn
}

output "deploy_role_name" {
  description = "Name of the deploy IAM role"
  value       = aws_iam_role.deploy.name
}
