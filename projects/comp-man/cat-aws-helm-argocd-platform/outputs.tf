output "argocd_release" {
  value = try(helm_release.argocd[0].name, null)
}

output "argo_rollouts_release" {
  value = try(helm_release.argo_rollouts[0].name, null)
}

output "argocd_namespace" {
  value = try(kubernetes_namespace_v1.argocd[0].metadata[0].name, null)
}

# The chart creates `argocd-initial-admin-secret` with a random password.
# Don't try to read it via terraform — it's a one-shot secret that should
# be rotated after first login.
output "argocd_initial_admin_password_cmd" {
  description = "Run after apply to fetch the initial admin password."
  value       = try("kubectl -n ${kubernetes_namespace_v1.argocd[0].metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d", null)
}
