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

# ── argocd ───────────────────────────────────────────────────────────────

variable "enable_argocd" {
  type    = bool
  default = true
}

variable "argocd_namespace" {
  type    = string
  default = "argocd"
}

variable "argocd_chart_version" {
  description = "Pin per env via configs/config-<env>.json. See https://github.com/argoproj/argo-helm/releases."
  type        = string
  default     = "7.7.0"
}

variable "argocd_domain" {
  description = "External hostname Argo CD serves on. Wire DNS / ingress separately; used in the chart's `global.domain`."
  type        = string
  default     = "argocd.local"
}

# ── argo-rollouts ────────────────────────────────────────────────────────

variable "enable_argo_rollouts" {
  type    = bool
  default = true
}

variable "argo_rollouts_namespace" {
  type    = string
  default = "argo-rollouts"
}

variable "argo_rollouts_chart_version" {
  description = "Pin per env via configs/config-<env>.json. See https://github.com/argoproj/argo-helm/releases."
  type        = string
  default     = "2.39.0"
}

variable "tags" {
  type    = map(string)
  default = {}
}
