module "eks" {
  source = "../../../template/modules/mod-aws-eks/v1.1.0"

  company                 = var.company
  project                 = var.project
  name                    = var.service_name
  environment             = var.environment
  suffix                  = var.suffix
  kubernetes_version      = var.kubernetes_version
  vpc_id                  = var.vpc_id
  subnet_ids              = var.subnet_ids
  enable_irsa             = var.enable_irsa
  endpoint_public_access  = var.cluster_endpoint_public_access
  endpoint_private_access = var.cluster_endpoint_private_access
  eks_managed_node_groups = var.eks_managed_node_groups
  addons                  = var.addons
  tags                    = var.tags
}
