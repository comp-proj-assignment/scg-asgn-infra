locals {
  # Single computed map keyed by the same keys the caller passed in.
  # Each value bundles every name variant + the tag set, so callers
  # only ever look up `module.naming.aws_resource["<key>"].<field>`.
  aws_resource = {
    "aws_vpc" : "vpc"
    "aws_subnet" : "sub"
    "aws_eks" : "eks"
    "aws_eks_cluster" : "eks"
    "aws_eks_node_group" : "ng"
  }
  helm_resource = {
    "fluent_bit" : "fluentb"
    "kube_prometheus_stack" : "promstk"
    "loki" : "loki"
  }
}
