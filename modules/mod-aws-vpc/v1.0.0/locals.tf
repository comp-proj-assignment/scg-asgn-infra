module "naming_convention" {
  # Path: v1.0.0 → mod-aws-vpc → modules → mod-naming-convention
  source = "../../mod-naming-convention"
}

locals {
  vpc_resource_abbr = module.naming_convention.aws_resource["aws_vpc"]
  subnet_resource_abbr = module.naming_convention.aws_resource["aws_subnet"]
  vpc_name = "${var.company}-${var.project}-${local.vpc_resource_abbr}-${var.name}-${var.environment}"
}
