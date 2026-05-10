output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "name" {
  value = module.vpc.name
}
