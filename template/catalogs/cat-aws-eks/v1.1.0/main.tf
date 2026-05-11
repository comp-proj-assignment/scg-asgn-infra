module "eks" {
  # Path is relative to the slot the pipeline renders this into:
  # projects/<proj>/<slot>/ → ../../../modules/mod-aws-eks/v1.0.0/terraform-aws-eks
  source = "../../../template/modules/mod-aws-eks/v1.1.0"

  # Naming inputs (read by mod-aws-eks/locals.tf via mod-naming-convention,
  # and passed down to submodules like eks-managed-node-group).
  company     = var.company
  project     = var.project
  name        = var.service_name
  environment = var.environment
  suffix      = var.suffix

  # Cluster shape (per-env values from configs/config-<env>.json).
  kubernetes_version = var.kubernetes_version
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  enable_irsa        = var.enable_irsa

  # Upstream module names these without the `cluster_` prefix; we keep
  # the friendlier `cluster_endpoint_*` names in our catalog config.
  endpoint_public_access  = var.cluster_endpoint_public_access
  endpoint_private_access = var.cluster_endpoint_private_access

  eks_managed_node_groups = var.eks_managed_node_groups

  tags = var.tags
}
