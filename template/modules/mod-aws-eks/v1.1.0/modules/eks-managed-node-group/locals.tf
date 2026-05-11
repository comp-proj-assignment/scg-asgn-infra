module "naming_convention" {
  # Path: eks-managed-node-group → modules → v1.1.0 → mod-aws-eks
  #       → modules → mod-naming-convention (4 levels up)
  source = "../../../../mod-naming-convention"
}

locals {
  eks_node_group_resource_abbr = module.naming_convention.aws_resource["aws_eks_node_group"]
}
