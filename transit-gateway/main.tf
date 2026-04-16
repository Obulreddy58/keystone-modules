locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

###############################################################################
# Transit Gateway
###############################################################################
resource "aws_ec2_transit_gateway" "this" {
  description = "${var.name} Transit Gateway"

  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation
  dns_support                     = var.dns_support
  vpn_ecmp_support                = var.vpn_ecmp_support

  tags = merge(local.common_tags, { Name = "${var.name}-tgw" })
}

###############################################################################
# VPC Attachments
###############################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = var.vpc_attachments

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = each.value.vpc_id
  subnet_ids         = each.value.subnet_ids
  dns_support        = each.value.dns_support

  transit_gateway_default_route_table_association = each.value.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = each.value.transit_gateway_default_route_table_propagation

  tags = merge(local.common_tags, { Name = "${var.name}-tgw-${each.key}" })
}

###############################################################################
# Resource Access Manager (cross-account sharing)
###############################################################################
resource "aws_ram_resource_share" "this" {
  count = length(var.ram_principals) > 0 ? 1 : 0

  name                      = "${var.name}-tgw-share"
  allow_external_principals = true

  tags = local.common_tags
}

resource "aws_ram_resource_association" "this" {
  count = length(var.ram_principals) > 0 ? 1 : 0

  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

resource "aws_ram_principal_association" "this" {
  count = length(var.ram_principals)

  principal          = var.ram_principals[count.index]
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

###############################################################################
# Flow Logs
###############################################################################
resource "aws_cloudwatch_log_group" "tgw_flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/tgw/flow-log/${var.name}"
  retention_in_days = var.flow_log_retention_days

  tags = local.common_tags
}

resource "aws_iam_role" "tgw_flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.name}-tgw-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "tgw_flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.name}-tgw-flow-log-policy"
  role = aws_iam_role.tgw_flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.tgw_flow_log[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "tgw" {
  count = var.enable_flow_logs ? 1 : 0

  transit_gateway_id       = aws_ec2_transit_gateway.this.id
  traffic_type             = "ALL"
  iam_role_arn             = aws_iam_role.tgw_flow_log[0].arn
  log_destination          = aws_cloudwatch_log_group.tgw_flow_log[0].arn
  log_destination_type     = "cloud-watch-logs"
  max_aggregation_interval = 60

  tags = merge(local.common_tags, { Name = "${var.name}-tgw-flow-log" })
}
