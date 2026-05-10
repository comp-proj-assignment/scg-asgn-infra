module "vpc" {
  # Path is relative to the slot the pipeline renders this into:
  # projects/<proj>/slots/<name>/ → ../../../../modules/mod-aws-vpc/v1.0.0
  source = "../../../../modules/mod-aws-vpc/v1.0.0"

  # Naming inputs (read by mod-aws-vpc/locals.tf via mod-naming-convention).
  company     = var.company
  project     = var.project
  name        = var.service_name
  environment = var.environment
  suffix      = var.suffix

  # Network shape (per-env values from configs/config-<env>.json).
  cidr               = var.cidr
  azs                = var.azs
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  enable_nat_gateway = var.enable_nat_gateway

  tags = var.tags
}
