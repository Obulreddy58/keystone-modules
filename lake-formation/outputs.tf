output "data_lake_settings_id" {
  description = "Lake Formation settings ID"
  value       = aws_lakeformation_data_lake_settings.this.id
}

output "service_role_arn" {
  description = "Lake Formation service role ARN"
  value       = aws_iam_role.lf_service.arn
}

output "catalog_id" {
  description = "Glue Catalog ID"
  value       = local.catalog_id
}

output "registered_locations" {
  description = "Registered S3 data lake locations"
  value       = [for r in aws_lakeformation_resource.locations : r.arn]
}

output "lf_tag_keys" {
  description = "Created LF-Tag keys"
  value       = [for t in aws_lakeformation_lf_tag.tags : t.key]
}
