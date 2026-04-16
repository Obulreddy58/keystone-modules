locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

###############################################################################
# EFS File System
###############################################################################
resource "aws_efs_file_system" "this" {
  creation_token   = var.name
  encrypted        = var.encrypted
  kms_key_id       = var.kms_key_arn
  performance_mode = var.performance_mode
  throughput_mode   = var.throughput_mode

  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  lifecycle_policy {
    transition_to_ia = var.lifecycle_policy_transition_to_ia
  }

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy_transition_to_primary != null ? [1] : []
    content {
      transition_to_primary_storage_class = var.lifecycle_policy_transition_to_primary
    }
  }

  tags = merge(local.common_tags, { Name = var.name })
}

###############################################################################
# Backup Policy
###############################################################################
resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.enable_backup ? "ENABLED" : "DISABLED"
  }
}

###############################################################################
# Mount Target Security Group
###############################################################################
resource "aws_security_group" "efs" {
  name_prefix = "${var.name}-efs-"
  description = "Security group for EFS mount targets"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name}-efs" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_sg" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.efs.id
  description                  = "NFS from allowed security group"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_cidr" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.efs.id
  description       = "NFS from CIDR"
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "efs_all" {
  security_group_id = aws_security_group.efs.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

###############################################################################
# Mount Targets (one per subnet / AZ)
###############################################################################
resource "aws_efs_mount_target" "this" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

###############################################################################
# Access Points
###############################################################################
resource "aws_efs_access_point" "this" {
  for_each = var.access_points

  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = each.value.posix_user.uid
    gid = each.value.posix_user.gid
  }

  root_directory {
    path = each.value.root_directory.path

    creation_info {
      owner_uid   = each.value.root_directory.creation_info.owner_uid
      owner_gid   = each.value.root_directory.creation_info.owner_gid
      permissions = each.value.root_directory.creation_info.permissions
    }
  }

  tags = merge(local.common_tags, { Name = "${var.name}-${each.key}" })
}

###############################################################################
# File System Policy – enforce encryption in transit
###############################################################################
data "aws_caller_identity" "current" {}

resource "aws_efs_file_system_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceEncryptionInTransit"
        Effect    = "Deny"
        Principal = { AWS = "*" }
        Action    = "*"
        Resource  = aws_efs_file_system.this.arn
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}
