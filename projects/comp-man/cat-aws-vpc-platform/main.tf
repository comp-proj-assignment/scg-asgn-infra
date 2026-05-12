module "vpc" {
  source = "../../../template/modules/mod-aws-vpc/v1.0.0"

  company               = var.company
  project               = var.project
  name                  = var.service_name
  environment           = var.environment
  suffix                = var.suffix
  cidr                  = var.cidr
  azs                   = var.azs
  public_subnets        = var.public_subnets
  private_subnets       = var.private_subnets
  public_subnet_suffix  = var.public_subnet_suffix
  private_subnet_suffix = var.private_subnet_suffix
  enable_nat_gateway    = var.enable_nat_gateway
  public_subnet_tags  = var.public_subnet_tags
  private_subnet_tags = var.private_subnet_tags

  tags = var.tags
}
