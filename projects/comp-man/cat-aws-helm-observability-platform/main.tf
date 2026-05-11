locals {
  loki_service_account_name = "${var.company}-${var.project}-loki-${var.service_name}-${var.environment}-sa"

  # Loki release name (must match helm_release.loki.name below) — Grafana
  # uses the release's primary Service, which the loki chart names after
  # the release in SingleBinary mode.
  loki_release_name = "${var.company}-${var.project}-loki-${var.service_name}-${var.environment}"
  loki_host         = "loki-headless.${var.namespace}.svc.cluster.local"
  loki_url          = "http://${local.loki_host}"
}

data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# ── fluent-bit ───────────────────────────────────────────────────────────
resource "helm_release" "fluent_bit" {
  count = var.enable_fluent_bit ? 1 : 0

  name             = "${var.company}-${var.project}-flbit-${var.service_name}-${var.environment}"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://fluent.github.io/helm-charts"
  chart            = "fluent-bit"
  version          = var.fluent_bit_chart_version

  values = [
    templatefile("./values/fluent-bit.yaml", {
      loki_host = local.loki_host
    })
  ]
}

# ── kube-prometheus-stack ────────────────────────────────────────────────
resource "random_password" "grafana_admin" {
  count = var.enable_kube_prometheus_stack ? 1 : 0

  length           = 24
  special          = true
  override_special = "!@#%^*-_=+"
}

resource "kubernetes_secret_v1" "grafana_admin" {
  count = var.enable_kube_prometheus_stack ? 1 : 0

  metadata {
    name      = "grafana-admin"
    namespace = var.namespace
  }

  data = {
    "admin-user"     = "admin"
    "admin-password" = random_password.grafana_admin[0].result
  }

  type = "Opaque"
}

resource "helm_release" "kube_prometheus_stack" {
  count = var.enable_kube_prometheus_stack ? 1 : 0

  name             = "${var.company}-${var.project}-promstk-${var.service_name}-${var.environment}"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.kube_prometheus_stack_chart_version
  replace          = true
  force_update     = true
  cleanup_on_fail  = true
  values = [
    templatefile("./values/kube-prometheus-stack.yaml", {
      enable_loki = var.enable_loki
      loki_url    = local.loki_url
    })
  ]

  depends_on = [kubernetes_secret_v1.grafana_admin]
}

module "loki_bucket" {
  count  = var.enable_loki ? 1 : 0
  source = "../../../template/modules/mod-aws-s3/v1.0.0"

  bucket = "${var.company}-${var.project}-loki-${data.aws_caller_identity.current.account_id}"

  versioning = { enabled = true }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    company     = var.company
    project     = var.project
    environment = var.environment
    component   = "loki"
  }
}

module "loki_irsa" {
  count  = var.enable_loki ? 1 : 0
  source = "../../../template/modules/mod-aws-iam-role/v1.1.0/modules/iam-role-for-service-accounts"

  name        = "${var.company}-${var.project}-s3-${var.service_name}-${var.environment}-loki"
  policy_name = "loki-s3"

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.this.arn
      namespace_service_accounts = ["${var.namespace}:${local.loki_service_account_name}"]
    }
  }

  permissions = {
    LokiBucketReadWrite = {
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
      ]
      resources = [
        module.loki_bucket[0].s3_bucket_arn,
        "${module.loki_bucket[0].s3_bucket_arn}/*",
      ]
    }
  }
}

resource "helm_release" "loki" {
  count = var.enable_loki ? 1 : 0

  name             = "${var.company}-${var.project}-loki-${var.service_name}-${var.environment}"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = var.loki_chart_version
  replace          = true
  force_update     = true
  cleanup_on_fail  = true

  values = [
    templatefile("./values/loki.yaml", {
      s3_bucket            = module.loki_bucket[0].s3_bucket_id
      iam_role_arn         = module.loki_irsa[0].arn
      service_account_name = local.loki_service_account_name
    })
  ]

  depends_on = [
    module.loki_bucket,
    module.loki_irsa,
  ]
}
