# Two opt-in helm releases:
#   - argo-cd (the GitOps control plane)
#   - argo-rollouts (progressive delivery controller)
# Each gated by an enable_* flag, each in its own namespace by convention.

resource "kubernetes_namespace_v1" "argocd" {
  count = var.enable_argocd ? 1 : 0
  metadata {
    name = var.argocd_namespace
  }
}

resource "kubernetes_namespace_v1" "argo_rollouts" {
  count = var.enable_argo_rollouts ? 1 : 0
  metadata {
    name = var.argo_rollouts_namespace
  }
}

# ── argocd ───────────────────────────────────────────────────────────────
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name             = "${var.company}-${var.project}-argocd-${var.service_name}-${var.environment}"
  namespace        = kubernetes_namespace_v1.argocd[0].metadata[0].name
  create_namespace = false
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version

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
  namespace        = kubernetes_namespace_v1.argo_rollouts[0].metadata[0].name
  create_namespace = false
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  version          = var.argo_rollouts_chart_version

  values = [
    templatefile("./values/argo-rollouts.yaml", {
      company = var.company
      project = var.project
    })
  ]
}
