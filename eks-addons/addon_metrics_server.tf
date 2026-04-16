###############################################################################
# Metrics Server
###############################################################################
resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = var.metrics_server_chart_version
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "args[0]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }

  depends_on = []
}
