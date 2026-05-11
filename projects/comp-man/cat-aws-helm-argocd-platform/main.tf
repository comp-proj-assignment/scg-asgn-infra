# Two opt-in helm releases:
#   - argo-cd (the GitOps control plane)
#   - argo-rollouts (progressive delivery controller)
# Each gated by an enable_* flag, each in its own namespace by convention.
# ── argocd ───────────────────────────────────────────────────────────────
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name             = "${var.company}-${var.project}-argocd-${var.service_name}-${var.environment}"
  namespace        = var.namespace
  create_namespace = false
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  replace          = true
  force_update     = true
  cleanup_on_fail  = true

  values = [
    templatefile("./values/argocd.yaml", {
      company = var.company
      project = var.project
      domain  = var.argocd_domain
    })
  ]
}

# ── argo-rollouts ────────────────────────────────────────────────────────
resource "helm_release" "argo_rollouts" {
  count = var.enable_argo_rollouts ? 1 : 0

  name             = "${var.company}-${var.project}-rollouts-${var.service_name}-${var.environment}"
  namespace        = var.namespace
  create_namespace = false
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  version          = var.argo_rollouts_chart_version
  replace          = true
  force_update     = true
  cleanup_on_fail  = true

  values = [
    templatefile("./values/argo-rollouts.yaml", {
      company = var.company
      project = var.project
    })
  ]
}
