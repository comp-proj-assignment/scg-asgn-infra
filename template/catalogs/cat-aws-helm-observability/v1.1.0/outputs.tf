output "fluent_bit_release" {
  value = try(helm_release.fluent_bit[0].name, null)
}

output "kube_prometheus_stack_release" {
  value = try(helm_release.kube_prometheus_stack[0].name, null)
}

# Sensitive — read it once after apply to log in to Grafana:
#   terraform output -raw grafana_admin_password
output "grafana_admin_password" {
  value     = try(random_password.grafana_admin[0].result, null)
  sensitive = true
}

output "grafana_admin_secret" {
  description = "k8s Secret name (in the observability namespace) holding the grafana admin user + password."
  value       = try(kubernetes_secret_v1.grafana_admin[0].metadata[0].name, null)
}

output "loki_release" {
  value = try(helm_release.loki[0].name, null)
}
