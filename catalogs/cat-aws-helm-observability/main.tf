

# ── fluent-bit ───────────────────────────────────────────────────────────
resource "helm_release" "fluent_bit" {
  count = var.enable_fluent_bit ? 1 : 0

  name             = "fluent-bit"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://fluent.github.io/helm-charts"
  chart            = "fluent-bit"
  version          = var.fluent_bit_chart_version

  values = compact([
    templatefile("${local.template_dir}/fluent-bit.yaml", local.template_vars),
    fileexists(local.overlays.fluent_bit) ? file(local.overlays.fluent_bit) : "",
  ])
}

# ── kube-prometheus-stack ────────────────────────────────────────────────
resource "helm_release" "kube_prometheus_stack" {
  count = var.enable_kube_prometheus_stack ? 1 : 0

  name             = "kube-prometheus-stack"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.kube_prometheus_stack_chart_version

  values = compact([
    templatefile("${local.template_dir}/kube-prometheus-stack.yaml", local.template_vars),
  ])
}

# ── loki ─────────────────────────────────────────────────────────────────
resource "helm_release" "loki" {
  count = var.enable_loki ? 1 : 0

  name             = "loki"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = var.loki_chart_version

  values = compact([
    templatefile("${local.template_dir}/loki.yaml", local.template_vars),
    fileexists(local.overlays.loki) ? file(local.overlays.loki) : "",
  ])
}
