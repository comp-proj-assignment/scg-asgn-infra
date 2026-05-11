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

variable "addons" {
  description = "Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `name`"
  type = map(object({
    name                 = optional(string) # will fall back to map key
    before_compute       = optional(bool, false)
    most_recent          = optional(bool, true)
    addon_version        = optional(string)
    configuration_values = optional(string)
    pod_identity_association = optional(list(object({
      role_arn        = string
      service_account = string
    })))
    preserve                    = optional(bool, true)
    resolve_conflicts_on_create = optional(string, "NONE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    service_account_role_arn    = optional(string)
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
    tags = optional(map(string), {})
  }))
  default = null
}