output "api_id" {
  description = "The API identifier"
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "The default endpoint URL"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "api_arn" {
  description = "The ARN of the API"
  value       = aws_apigatewayv2_api.this.arn
}

output "execution_arn" {
  description = "The execution ARN (for Lambda permissions)"
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "stage_id" {
  description = "The stage identifier"
  value       = aws_apigatewayv2_stage.this.id
}

output "stage_invoke_url" {
  description = "The URL to invoke the API stage"
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "custom_domain_name" {
  description = "The custom domain name"
  value       = try(aws_apigatewayv2_domain_name.this[0].domain_name, null)
}

output "custom_domain_target" {
  description = "The target domain name for Route53 alias"
  value       = try(aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].target_domain_name, null)
}

output "custom_domain_hosted_zone_id" {
  description = "The hosted zone ID for the custom domain (for Route53 alias)"
  value       = try(aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].hosted_zone_id, null)
}
