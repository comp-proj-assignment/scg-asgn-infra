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

variable "namespace" {
  description = "Kubernetes namespace to install the releases into."
  type        = string
  default     = "observability"
}

# ── opt-in toggles ───────────────────────────────────────────────────────

variable "enable_fluent_bit" {
  type    = bool
  default = false
}

variable "enable_kube_prometheus_stack" {
  type    = bool
  default = false
}

variable "enable_loki" {
  type    = bool
  default = false
}

variable "enable_metrics_server" {
  type    = bool
  default = false
}

# ── chart versions (pin per env via configs/config-<env>.json) ───────────

variable "fluent_bit_chart_version" {
  type    = string
  default = "0.49.1"
}

variable "kube_prometheus_stack_chart_version" {
  type    = string
  default = "65.5.0"
}

variable "loki_chart_version" {
  type    = string
  default = "6.18.0"
}

variable "metrics_server_chart_version" {
  type    = string
  default = "3.12.2"
}

variable "tags" {
  type    = map(string)
  default = {}
}
