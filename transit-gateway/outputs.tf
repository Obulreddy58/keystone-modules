output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.this.id
}

output "transit_gateway_arn" {
  description = "Transit Gateway ARN"
  value       = aws_ec2_transit_gateway.this.arn
}

output "transit_gateway_owner_id" {
  description = "Owner account ID"
  value       = aws_ec2_transit_gateway.this.owner_id
}

output "transit_gateway_route_table_id" {
  description = "Default route table ID"
  value       = aws_ec2_transit_gateway.this.association_default_route_table_id
}

output "vpc_attachment_ids" {
  description = "Map of VPC attachment IDs"
  value       = { for k, v in aws_ec2_transit_gateway_vpc_attachment.this : k => v.id }
}

output "ram_resource_share_arn" {
  description = "ARN of the RAM resource share"
  value       = length(aws_ram_resource_share.this) > 0 ? aws_ram_resource_share.this[0].arn : null
}
