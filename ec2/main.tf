data "aws_partition" "current" {}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
  partition = data.aws_partition.current.partition
  ami_id    = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023.id
}

###############################################################################
# IAM Instance Profile (SSM access by default)
###############################################################################
resource "aws_iam_role" "instance" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.iam_policies)

  role       = aws_iam_role.instance.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.instance.name
  tags = local.common_tags
}

###############################################################################
# Security Group
###############################################################################
resource "aws_security_group" "this" {
  name_prefix = "${var.name}-ec2-"
  description = "Security group for ${var.name} EC2 instances"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name}-ec2-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "ingress" {
  count = length(var.ingress_rules)

  type              = "ingress"
  from_port         = var.ingress_rules[count.index].from_port
  to_port           = var.ingress_rules[count.index].to_port
  protocol          = var.ingress_rules[count.index].protocol
  cidr_blocks       = length(var.ingress_rules[count.index].cidr_blocks) > 0 ? var.ingress_rules[count.index].cidr_blocks : null
  security_group_id = aws_security_group.this.id
  description       = var.ingress_rules[count.index].description

  source_security_group_id = length(var.ingress_rules[count.index].security_groups) > 0 ? var.ingress_rules[count.index].security_groups[0] : null
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
  description       = "Allow all egress"
}

###############################################################################
# EC2 Instances
###############################################################################
resource "aws_instance" "this" {
  count = var.instance_count

  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  key_name                    = var.key_name != "" ? var.key_name : null
  ebs_optimized               = var.ebs_optimized
  monitoring                  = var.monitoring
  associate_public_ip_address = var.associate_public_ip
  user_data_base64            = var.user_data != "" ? var.user_data : null

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = var.metadata_http_tokens
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = var.root_volume_encrypted
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = var.instance_count > 1 ? "${var.name}-${count.index + 1}" : var.name
  })

  volume_tags = merge(local.common_tags, {
    Name = "${var.name}-root-${count.index + 1}"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}
