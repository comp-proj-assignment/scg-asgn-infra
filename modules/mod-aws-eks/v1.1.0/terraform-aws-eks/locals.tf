module "naming_convention" {
  # Path: terraform-aws-eks → v1.0.0 → mod-aws-eks → modules/mod-naming-convention
  source = "../../../mod-naming-convention"
}

locals {
  eks_resource_abbr = module.naming_convention.aws_resource["aws_eks"]
  eks_name = "${var.company}-${var.project}-${local.eks_resource_abbr}-${var.name}-${var.environment}"
}
