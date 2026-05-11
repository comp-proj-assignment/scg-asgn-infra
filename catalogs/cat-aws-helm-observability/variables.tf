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

# Target cluster identity. Usually wired in from the cat-aws-eks slot
# in the same project (terraform_remote_state, or hand-set here for now).
variable "cluster_name" {
  description = "EKS cluster name the helm releases target."
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS API endpoint URL."
  type        = string
}

variable "cluster_ca_data" {
  description = "Base64-encoded EKS CA bundle (output `cluster_certificate_authority_data` from cat-aws-eks)."
  type        = string
  sensitive   = true
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

variable "tags" {
  type    = map(string)
  default = {}
}
