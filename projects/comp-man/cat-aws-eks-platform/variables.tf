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
