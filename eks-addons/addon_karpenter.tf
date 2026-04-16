###############################################################################
# Karpenter — IRSA Role
###############################################################################
resource "aws_iam_role" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name               = "${var.cluster_name}-karpenter"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust["karpenter"].json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name   = "karpenter"
  role   = aws_iam_role.karpenter[0].id
  policy = data.aws_iam_policy_document.karpenter[0].json
}

data "aws_iam_policy_document" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  # EC2 fleet / launch permissions
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:RunInstances",
      "ec2:CreateTags",
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSpotPriceHistory",
    ]
    resources = ["*"]
  }

  # SSM for AMI discovery
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:${local.partition}:ssm:*:*:parameter/aws/service/*"]
  }

  # EKS describe
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:${local.partition}:eks:*:${local.account_id}:cluster/${var.cluster_name}"]
  }

  # Pass role to EC2 instances
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [var.karpenter_node_role_arn != "" ? var.karpenter_node_role_arn : "arn:${local.partition}:iam::${local.account_id}:role/*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  # Instance profile management
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }
  }

  # Pricing and SQS (for spot interruption)
  statement {
    effect = "Allow"
    actions = [
      "pricing:GetProducts",
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = ["*"]
  }
}

###############################################################################
# Karpenter — SQS Queue for Spot Interruption
###############################################################################
resource "aws_sqs_queue" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name                       = "${var.cluster_name}-karpenter"
  message_retention_seconds  = 300
  sqs_managed_sse_enabled    = true

  tags = merge(local.common_tags, { Name = "${var.cluster_name}-karpenter" })
}

resource "aws_sqs_queue_policy" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  queue_url = aws_sqs_queue.karpenter[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EC2InterruptionPolicy"
        Effect    = "Allow"
        Principal = { Service = ["events.amazonaws.com", "sqs.amazonaws.com"] }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.karpenter[0].arn
      }
    ]
  })
}

# EventBridge rules for spot interruption, rebalance, state change, health
resource "aws_cloudwatch_event_rule" "karpenter_spot_interruption" {
  count = var.enable_karpenter ? 1 : 0

  name = "${var.cluster_name}-karpenter-spot-interruption"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "karpenter_spot_interruption" {
  count = var.enable_karpenter ? 1 : 0

  rule      = aws_cloudwatch_event_rule.karpenter_spot_interruption[0].name
  target_id = "karpenter"
  arn       = aws_sqs_queue.karpenter[0].arn
}

resource "aws_cloudwatch_event_rule" "karpenter_rebalance" {
  count = var.enable_karpenter ? 1 : 0

  name = "${var.cluster_name}-karpenter-rebalance"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "karpenter_rebalance" {
  count = var.enable_karpenter ? 1 : 0

  rule      = aws_cloudwatch_event_rule.karpenter_rebalance[0].name
  target_id = "karpenter"
  arn       = aws_sqs_queue.karpenter[0].arn
}

resource "aws_cloudwatch_event_rule" "karpenter_instance_state" {
  count = var.enable_karpenter ? 1 : 0

  name = "${var.cluster_name}-karpenter-instance-state"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "karpenter_instance_state" {
  count = var.enable_karpenter ? 1 : 0

  rule      = aws_cloudwatch_event_rule.karpenter_instance_state[0].name
  target_id = "karpenter"
  arn       = aws_sqs_queue.karpenter[0].arn
}

###############################################################################
# Karpenter — Helm Release
###############################################################################
resource "helm_release" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_chart_version
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = var.cluster_endpoint
  }

  set {
    name  = "settings.interruptionQueue"
    value = aws_sqs_queue.karpenter[0].name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter[0].arn
  }

  set {
    name  = "replicas"
    value = "2"
  }
}
