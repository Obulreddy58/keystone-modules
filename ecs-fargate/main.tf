data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

###############################################################################
# ECS Cluster
###############################################################################
resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.exec.name
      }
    }
  }

  tags = merge(local.common_tags, { Name = var.name })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

###############################################################################
# CloudWatch Log Groups
###############################################################################
resource "aws_cloudwatch_log_group" "exec" {
  name              = "/aws/ecs/${var.name}/exec"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "service" {
  for_each = var.services

  name              = "/aws/ecs/${var.name}/${each.key}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

###############################################################################
# Task Execution Role (pulls images, writes logs)
###############################################################################
resource "aws_iam_role" "execution" {
  name = "${var.name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  name = "${var.name}-ecs-execution-secrets"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "ssm:GetParameters",
        "kms:Decrypt"
      ]
      Resource = "*"
    }]
  })
}

###############################################################################
# Task Role (what the container can do)
###############################################################################
resource "aws_iam_role" "task" {
  name = "${var.name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

###############################################################################
# Security Group
###############################################################################
resource "aws_security_group" "ecs" {
  name_prefix = "${var.name}-ecs-"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name}-ecs-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "ecs_ingress" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.ecs.id
  description              = "Allow from ${each.value}"
}

resource "aws_security_group_rule" "ecs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
  description       = "Allow all egress"
}

###############################################################################
# Task Definitions + Services
###############################################################################
resource "aws_ecs_task_definition" "this" {
  for_each = var.services

  family                   = "${var.name}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name      = each.key
    image     = each.value.image
    essential = true

    portMappings = [{
      containerPort = each.value.container_port
      protocol      = "tcp"
    }]

    environment = [
      for k, v in each.value.environment_vars : { name = k, value = v }
    ]

    secrets = [
      for k, v in each.value.secrets : { name = k, valueFrom = v }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.service[each.key].name
        "awslogs-region"        = local.region
        "awslogs-stream-prefix" = each.key
      }
    }
  }])

  tags = merge(local.common_tags, { Name = "${var.name}-${each.key}" })
}

resource "aws_ecs_service" "this" {
  for_each = var.services

  name            = each.key
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = each.value.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = each.value.target_group_arn != "" ? [1] : []
    content {
      target_group_arn = each.value.target_group_arn
      container_name   = each.key
      container_port   = each.value.container_port
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  tags = merge(local.common_tags, { Name = "${var.name}-${each.key}" })

  lifecycle {
    ignore_changes = [desired_count]
  }
}

###############################################################################
# Auto Scaling
###############################################################################
resource "aws_appautoscaling_target" "this" {
  for_each = { for k, v in var.services : k => v if v.enable_autoscaling }

  max_capacity       = each.value.max_count
  min_capacity       = each.value.min_count
  resource_id        = "service/${aws_ecs_cluster.this.name}/${each.key}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.this]
}

resource "aws_appautoscaling_policy" "cpu" {
  for_each = { for k, v in var.services : k => v if v.enable_autoscaling }

  name               = "${var.name}-${each.key}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = each.value.cpu_threshold
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
