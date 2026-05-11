################################################################################
# From common-config.json (project-wide, supplied by the pipeline -var-file)
################################################################################

variable "company" {
  type = string
}

variable "project" {
  type = string
}

# Pipeline writes the remote_state block to common-config.json; declared
# here so the whole file passes as tfvars without "undeclared" warnings.
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

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}

variable "vpc_id" {
  description = "ID of the VPC the cluster will live in. Usually wired in from the cat-aws-vpc slot in the same project."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the cluster + managed node groups."
  type        = list(string)
}

variable "enable_irsa" {
  type    = bool
  default = true
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = false
}

variable "cluster_endpoint_private_access" {
  type    = bool
  default = true
}

variable "eks_managed_node_groups" {
  description = "Map of managed node group definitions. Keys become node-group names."
  type        = any
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ── Cluster addons (managed by EKS) ──────────────────────────────────────
variable "addons" {
  description = "EKS managed addons. Maps to the module's cluster_addons input. Each value supports: most_recent, configuration_values, resolve_conflicts_on_create, resolve_conflicts_on_update, before_compute."
  type        = any
  default     = {}
}

# ── Cluster access control ───────────────────────────────────────────────
variable "authentication_mode" {
  description = "EKS authentication mode. 'API' = access entries only. 'API_AND_CONFIG_MAP' = also support the legacy aws-auth ConfigMap."
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "enable_cluster_creator_admin_permissions" {
  description = "If true, the IAM principal running terraform gets a cluster-admin access entry automatically."
  type        = bool
  default     = true
}

variable "access_entries" {
  description = "Additional access entries to grant cluster access. Map of {key = {principal_arn, policy_associations}}."
  type        = any
  default     = {}
}
