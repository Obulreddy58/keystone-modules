###############################################################################
# Cluster connection
###############################################################################
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded cluster CA certificate"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IRSA"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider (without https://)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster runs"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

###############################################################################
# Feature flags — enable/disable each operator
###############################################################################
variable "enable_argocd" {
  description = "Install ArgoCD"
  type        = bool
  default     = true
}

variable "enable_aws_load_balancer_controller" {
  description = "Install AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_karpenter" {
  description = "Install Karpenter autoscaler"
  type        = bool
  default     = true
}

variable "enable_external_secrets" {
  description = "Install External Secrets Operator (ESO)"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Install cert-manager"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Install Metrics Server"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Install ExternalDNS"
  type        = bool
  default     = false
}

###############################################################################
# ArgoCD settings
###############################################################################
variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.7.16"
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_values" {
  description = "Additional ArgoCD Helm values (YAML string)"
  type        = string
  default     = ""
}

###############################################################################
# AWS Load Balancer Controller settings
###############################################################################
variable "aws_lb_controller_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
  default     = "1.11.0"
}

###############################################################################
# Karpenter settings
###############################################################################
variable "karpenter_chart_version" {
  description = "Karpenter Helm chart version"
  type        = string
  default     = "1.1.1"
}

variable "karpenter_node_role_arn" {
  description = "ARN of the IAM role for Karpenter-provisioned nodes (typically the existing node group role)"
  type        = string
  default     = ""
}

variable "karpenter_instance_profile_name" {
  description = "EC2 instance profile name for Karpenter nodes (created if empty)"
  type        = string
  default     = ""
}

###############################################################################
# External Secrets Operator settings
###############################################################################
variable "external_secrets_chart_version" {
  description = "External Secrets Operator Helm chart version"
  type        = string
  default     = "0.14.3"
}

variable "external_secrets_allowed_secret_arns" {
  description = "List of Secrets Manager / SSM ARN patterns ESO is allowed to read"
  type        = list(string)
  default     = ["arn:aws:secretsmanager:*:*:secret:*", "arn:aws:ssm:*:*:parameter/*"]
}

###############################################################################
# cert-manager settings
###############################################################################
variable "cert_manager_chart_version" {
  description = "cert-manager Helm chart version"
  type        = string
  default     = "v1.17.1"
}

variable "cert_manager_enable_route53_solver" {
  description = "Create IRSA role for cert-manager DNS-01 solver via Route53"
  type        = bool
  default     = false
}

variable "cert_manager_hosted_zone_arns" {
  description = "Route53 hosted zone ARNs that cert-manager can manage"
  type        = list(string)
  default     = []
}

###############################################################################
# Metrics Server settings
###############################################################################
variable "metrics_server_chart_version" {
  description = "Metrics Server Helm chart version"
  type        = string
  default     = "3.12.2"
}

###############################################################################
# ExternalDNS settings
###############################################################################
variable "external_dns_chart_version" {
  description = "ExternalDNS Helm chart version"
  type        = string
  default     = "1.15.0"
}

variable "external_dns_hosted_zone_arns" {
  description = "Route53 hosted zone ARNs that ExternalDNS can manage"
  type        = list(string)
  default     = []
}

variable "external_dns_domain_filters" {
  description = "Domain names to filter (only manage records for these domains)"
  type        = list(string)
  default     = []
}

###############################################################################
# Common
###############################################################################
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
