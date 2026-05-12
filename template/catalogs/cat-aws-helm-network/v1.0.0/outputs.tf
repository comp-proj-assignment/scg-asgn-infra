output "aws_lb_controller_release" {
  value = try(helm_release.aws_lb_controller[0].name, null)
}

output "aws_lb_controller_role_arn" {
  description = "IAM role assumed by the LB controller via EKS Pod Identity."
  value       = try(module.aws_lb_controller_role[0].arn, null)
}

output "nginx_ingress_release" {
  value = try(helm_release.nginx_ingress[0].name, null)
}

output "cert_manager_release" {
  value = try(helm_release.cert_manager[0].name, null)
}
