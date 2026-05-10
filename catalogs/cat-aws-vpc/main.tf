module "vpc" {
  source = "../../modules/mod-aws-vpc"

  company      = var.company
  project      = var.project
  service_name = var.service_name
  env          = var.env
  suffix       = var.suffix
  cidr         = var.cidr
  tags         = var.tags
}
