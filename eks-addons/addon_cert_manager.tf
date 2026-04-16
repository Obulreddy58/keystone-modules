###############################################################################
# cert-manager — Helm Release (no IRSA needed unless using DNS-01 solver)
###############################################################################
resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_chart_version
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = "cert-manager"
  }

  dynamic "set" {
    for_each = var.cert_manager_enable_route53_solver ? [1] : []
    content {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.cert_manager[0].arn
    }
  }

  set {
    name  = "enableCertificateOwnerRef"
    value = "true"
  }
}

###############################################################################
# cert-manager — IRSA Role (only for DNS-01 Route53 solver)
###############################################################################
resource "aws_iam_role" "cert_manager" {
  count = var.enable_cert_manager && var.cert_manager_enable_route53_solver ? 1 : 0

  name               = "${var.cluster_name}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust["cert-manager"].json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "cert_manager" {
  count = var.enable_cert_manager && var.cert_manager_enable_route53_solver ? 1 : 0

  name   = "cert-manager-route53"
  role   = aws_iam_role.cert_manager[0].id
  policy = data.aws_iam_policy_document.cert_manager[0].json
}

data "aws_iam_policy_document" "cert_manager" {
  count = var.enable_cert_manager && var.cert_manager_enable_route53_solver ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "route53:GetChange",
    ]
    resources = ["arn:${local.partition}:route53:::change/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = length(var.cert_manager_hosted_zone_arns) > 0 ? var.cert_manager_hosted_zone_arns : ["arn:${local.partition}:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZonesByName",
      "route53:ListHostedZones",
    ]
    resources = ["*"]
  }
}
