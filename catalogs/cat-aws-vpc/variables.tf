variable "company" {
  type = string
}

variable "project" {
  type = string
}

variable "service_name" {
  type = string
}

variable "env" {
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

variable "tags" {
  type    = map(string)
  default = {}
}

# Accepted from common-config.json (-var-file) so the whole file passes as tfvars.
# Consumed by the pipeline for backend.hcl generation, not by terraform code.
variable "remote_state" {
  type    = any
  default = null
}
