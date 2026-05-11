output "argocd_release" {
  value = try(helm_release.argocd[0].name, null)
}

output "argo_rollouts_release" {
  value = try(helm_release.argo_rollouts[0].name, null)
}