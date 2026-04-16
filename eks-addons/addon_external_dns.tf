###############################################################################
# ExternalDNS — IRSA Role
###############################################################################
resource "aws_iam_role" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name               = "${var.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust["external-dns"].json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name   = "external-dns"
  role   = aws_iam_role.external_dns[0].id
  policy = data.aws_iam_policy_document.external_dns[0].json
}

data "aws_iam_policy_document" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = length(var.external_dns_hosted_zone_arns) > 0 ? var.external_dns_hosted_zone_arns : ["arn:${local.partition}:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

###############################################################################
# ExternalDNS — Helm Release
###############################################################################
resource "helm_release" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = var.external_dns_chart_version
  namespace        = "external-dns"
  create_namespace = true

  set {
    name  = "provider.name"
    value = "aws"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns[0].arn
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "txtOwnerId"
    value = var.cluster_name
  }

  dynamic "set" {
    for_each = var.external_dns_domain_filters
    content {
      name  = "domainFilters[${set.key}]"
      value = set.value
    }
  }

  set {
    name  = "sources[0]"
    value = "service"
  }

  set {
    name  = "sources[1]"
    value = "ingress"
  }
}
