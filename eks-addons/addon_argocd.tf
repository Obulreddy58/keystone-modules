###############################################################################
# ArgoCD — Helm Release
# No IRSA needed — ArgoCD manages K8s resources, not AWS resources
###############################################################################
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = var.argocd_namespace
  create_namespace = true

  # HA mode for production
  set {
    name  = "controller.replicas"
    value = var.environment == "prod" ? "2" : "1"
  }

  set {
    name  = "server.replicas"
    value = var.environment == "prod" ? "2" : "1"
  }

  set {
    name  = "repoServer.replicas"
    value = var.environment == "prod" ? "2" : "1"
  }

  set {
    name  = "applicationSet.replicas"
    value = var.environment == "prod" ? "2" : "1"
  }

  # Disable insecure access — use port-forward or Ingress with TLS
  set {
    name  = "configs.params.server\\.insecure"
    value = "false"
  }

  # Dex disabled by default — enable if using SSO
  set {
    name  = "dex.enabled"
    value = "false"
  }

  # Additional user-provided values
  values = var.argocd_values != "" ? [var.argocd_values] : []
}
