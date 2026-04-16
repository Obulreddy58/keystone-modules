###############################################################################
# External Secrets Operator — IRSA Role
###############################################################################
resource "aws_iam_role" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust["external-secrets"].json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name   = "external-secrets"
  role   = aws_iam_role.external_secrets[0].id
  policy = data.aws_iam_policy_document.external_secrets[0].json
}

data "aws_iam_policy_document" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = var.external_secrets_allowed_secret_arns
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = var.external_secrets_allowed_secret_arns
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["secretsmanager.*.amazonaws.com", "ssm.*.amazonaws.com"]
    }
  }
}

###############################################################################
# External Secrets Operator — Helm Release
###############################################################################
resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  namespace        = "external-secrets"
  create_namespace = true

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_secrets[0].arn
  }

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "webhook.port"
    value = "9443"
  }
}
