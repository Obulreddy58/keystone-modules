locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

###############################################################################
# IRSA helper – reusable trust policy
###############################################################################
data "aws_iam_policy_document" "irsa_trust" {
  for_each = toset(compact([
    var.enable_aws_load_balancer_controller ? "aws-load-balancer-controller" : "",
    var.enable_karpenter ? "karpenter" : "",
    var.enable_external_secrets ? "external-secrets" : "",
    var.enable_cert_manager && var.cert_manager_enable_route53_solver ? "cert-manager" : "",
    var.enable_external_dns ? "external-dns" : "",
  ]))

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values = [
        each.key == "aws-load-balancer-controller" ? "system:serviceaccount:kube-system:aws-load-balancer-controller" :
        each.key == "karpenter" ? "system:serviceaccount:kube-system:karpenter" :
        each.key == "external-secrets" ? "system:serviceaccount:external-secrets:external-secrets" :
        each.key == "cert-manager" ? "system:serviceaccount:cert-manager:cert-manager" :
        each.key == "external-dns" ? "system:serviceaccount:external-dns:external-dns" :
        ""
      ]
    }
  }
}
