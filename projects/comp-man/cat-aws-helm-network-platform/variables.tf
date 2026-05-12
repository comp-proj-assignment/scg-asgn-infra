################################################################################
# From common-config.json (project-wide)
################################################################################

variable "company" {
  type = string
}

variable "project" {
  type = string
}

variable "remote_state" {
  type    = any
  default = null
}

################################################################################
# From configs/config-<env>.json (rendered by infra-request)
################################################################################

variable "service_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "suffix" {
  type    = string
  default = ""
}

variable "cluster_name" {
  description = "EKS cluster name the helm releases target."
  type        = string
}

# ── aws-load-balancer-controller ────────────────────────────────────────

variable "enable_aws_lb_controller" {
  type    = bool
  default = true
}

variable "aws_lb_controller" {
}
variable "aws_lb_controller_namespace" {
  description = "Namespace the LB controller runs in. EKS expects `kube-system` for the Pod Identity association to work cleanly; override only if you really know why."
  type        = string
  default     = "kube-system"
}

variable "aws_lb_controller_chart_version" {
  description = "Pin per env. See https://github.com/aws/eks-charts/releases."
  type        = string
  default     = "1.10.0"
}

# ── nginx-ingress ───────────────────────────────────────────────────────

variable "enable_nginx_ingress" {
  type    = bool
  default = true
}

variable "nginx_ingress_namespace" {
  type    = string
  default = "ingress-nginx"
}

variable "nginx_ingress_chart_version" {
  description = "Pin per env. See https://github.com/kubernetes/ingress-nginx/releases."
  type        = string
  default     = "4.11.3"
}

# ── cert-manager ────────────────────────────────────────────────────────

variable "enable_cert_manager" {
  type    = bool
  default = true
}

variable "cert_manager_namespace" {
  type    = string
  default = "cert-manager"
}

variable "cert_manager_chart_version" {
  description = "Pin per env. See https://github.com/cert-manager/cert-manager/releases."
  type        = string
  default     = "v1.16.1"
}

variable "tags" {
  type    = map(string)
  default = {}
}
