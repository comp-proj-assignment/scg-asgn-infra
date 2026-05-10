locals {
  resource_abbr = "vpc"

  raw           = "${var.company}-${var.project}-${local.resource_abbr}-${var.service_name}-${var.env}${var.suffix}"
  aws_resource  = local.raw
  helm_resource = substr(lower(replace(local.raw, "_", "-")), 0, 53)
}
