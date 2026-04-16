output "account_id" {
  description = "The 12-digit AWS account ID"
  value       = aws_organizations_account.team.id
}

output "account_arn" {
  description = "ARN of the AWS account"
  value       = aws_organizations_account.team.arn
}

output "account_name" {
  description = "Friendly name of the AWS account"
  value       = aws_organizations_account.team.name
}

output "admin_role_arn" {
  description = "ARN of the OrganizationAccountAccessRole in the new account"
  value       = "arn:aws:iam::${aws_organizations_account.team.id}:role/${var.admin_role_name}"
}

output "account_email" {
  description = "Root email of the account"
  value       = aws_organizations_account.team.email
}
