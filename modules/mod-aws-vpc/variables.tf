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
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
