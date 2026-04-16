locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Collect all attribute definitions needed for keys + GSI/LSI keys
  gsi_attributes = flatten([
    for gsi in var.global_secondary_indexes : concat(
      [{ name = gsi.hash_key, type = gsi.hash_key_type }],
      gsi.range_key != null ? [{ name = gsi.range_key, type = gsi.range_key_type }] : []
    )
  ])

  lsi_attributes = [
    for lsi in var.local_secondary_indexes : { name = lsi.range_key, type = lsi.range_key_type }
  ]

  all_attributes = concat(
    [{ name = var.hash_key, type = var.hash_key_type }],
    var.range_key != null ? [{ name = var.range_key, type = var.range_key_type }] : [],
    local.gsi_attributes,
    local.lsi_attributes,
  )

  # Deduplicate by attribute name
  unique_attributes = { for attr in local.all_attributes : attr.name => attr.type }
}

###############################################################################
# DynamoDB Table
###############################################################################
resource "aws_dynamodb_table" "this" {
  name         = var.name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key
  table_class  = var.table_class

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  deletion_protection_enabled = var.enable_deletion_protection

  dynamic "attribute" {
    for_each = local.unique_attributes
    content {
      name = attribute.key
      type = attribute.value
    }
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = var.kms_key_arn != null
    kms_key_arn = var.kms_key_arn
  }

  dynamic "ttl" {
    for_each = var.ttl_attribute != "" ? [1] : []
    content {
      attribute_name = var.ttl_attribute
      enabled        = true
    }
  }

  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_enabled ? var.stream_view_type : null

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
      read_capacity      = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity     = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes
    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = local_secondary_index.value.non_key_attributes
    }
  }

  dynamic "replica" {
    for_each = toset(var.replica_regions)
    content {
      region_name = replica.value
    }
  }

  tags = merge(local.common_tags, { Name = var.name })
}

###############################################################################
# Auto Scaling (only for PROVISIONED billing)
###############################################################################
resource "aws_appautoscaling_target" "read" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_read_max
  min_capacity       = var.autoscaling_read_min
  resource_id        = "table/${aws_dynamodb_table.this.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${var.name}-read-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read[0].resource_id
  scalable_dimension = aws_appautoscaling_target.read[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.autoscaling_target_utilization
  }
}

resource "aws_appautoscaling_target" "write" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_write_max
  min_capacity       = var.autoscaling_write_min
  resource_id        = "table/${aws_dynamodb_table.this.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "write" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${var.name}-write-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write[0].resource_id
  scalable_dimension = aws_appautoscaling_target.write[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.autoscaling_target_utilization
  }
}
