output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Invoke ARN (for API Gateway integration)"
  value       = aws_lambda_function.this.invoke_arn
}

output "role_name" {
  description = "Execution role name"
  value       = aws_iam_role.lambda.name
}

output "role_arn" {
  description = "Execution role ARN"
  value       = aws_iam_role.lambda.arn
}
