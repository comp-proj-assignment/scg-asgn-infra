output "fluent_bit_release" {
  value = try(helm_release.fluent_bit[0].name, null)
}

output "kube_prometheus_stack_release" {
  value = try(helm_release.kube_prometheus_stack[0].name, null)
}

output "loki_release" {
  value = try(helm_release.loki[0].name, null)
}
