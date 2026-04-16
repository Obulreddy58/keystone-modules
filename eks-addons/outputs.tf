###############################################################################
# IRSA Role ARNs
###############################################################################
output "aws_lb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = try(aws_iam_role.aws_lb_controller[0].arn, null)
}

output "karpenter_role_arn" {
  description = "IAM role ARN for Karpenter"
  value       = try(aws_iam_role.karpenter[0].arn, null)
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = try(aws_iam_role.external_secrets[0].arn, null)
}

output "cert_manager_role_arn" {
  description = "IAM role ARN for cert-manager"
  value       = try(aws_iam_role.cert_manager[0].arn, null)
}

output "external_dns_role_arn" {
  description = "IAM role ARN for ExternalDNS"
  value       = try(aws_iam_role.external_dns[0].arn, null)
}

###############################################################################
# Helm release status
###############################################################################
output "installed_addons" {
  description = "Map of addon name to installed version"
  value = merge(
    var.enable_argocd ? { argocd = helm_release.argocd[0].version } : {},
    var.enable_aws_load_balancer_controller ? { aws_load_balancer_controller = helm_release.aws_load_balancer_controller[0].version } : {},
    var.enable_karpenter ? { karpenter = helm_release.karpenter[0].version } : {},
    var.enable_external_secrets ? { external_secrets = helm_release.external_secrets[0].version } : {},
    var.enable_cert_manager ? { cert_manager = helm_release.cert_manager[0].version } : {},
    var.enable_metrics_server ? { metrics_server = helm_release.metrics_server[0].version } : {},
    var.enable_external_dns ? { external_dns = helm_release.external_dns[0].version } : {},
  )
}

###############################################################################
# Karpenter
###############################################################################
output "karpenter_queue_name" {
  description = "SQS queue name for Karpenter spot interruption"
  value       = try(aws_sqs_queue.karpenter[0].name, null)
}

###############################################################################
# ArgoCD
###############################################################################
output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = var.enable_argocd ? var.argocd_namespace : null
}
