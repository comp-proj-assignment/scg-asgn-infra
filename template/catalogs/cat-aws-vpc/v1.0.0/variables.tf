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
# Consumed by the pipeline for backend.hcl generation, not by terraform code.
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

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = []
}

variable "public_subnets" {
  type    = list(string)
  default = []
}

variable "public_subnet_suffix" {
  description = "Suffix to append to public subnets name"
  type        = string
  default     = "public"
}

variable "private_subnets" {
  type    = list(string)
  default = []
}

variable "private_subnet_suffix" {
  description = "Suffix to append to private subnets name"
  type        = string
  default     = "private"
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
