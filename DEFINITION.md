# comp-proj-infra

Infrastructure as Code for COMP application platform. Provisions cloud
resources, Kubernetes clusters, and platform services (Argo CD, Nexus,
monitoring stack).

## What This Repo Contains

```
comp-proj-infra/
├── terraform/
│   ├── modules/                      # Reusable Terraform modules
│   │   ├── eks-cluster/
│   │   ├── rds-postgres/
│   │   ├── elasticache-redis/
│   │   ├── s3-bucket/
│   │   └── vpc/
│   ├── environments/
│   │   ├── dev/
│   │   ├── qa/
│   │   ├── staging/
│   │   └── prod/
│   └── shared/                       # Cross-env resources
│       ├── nexus/
│       ├── monitoring/
│       └── argocd/
├── helm-charts/
│   ├── argocd/                       # Argo CD installation
│   ├── nexus/                        # Nexus repository manager
│   ├── reloader/                     # Stakater Reloader
│   ├── prometheus/                   # Monitoring stack
│   └── external-secrets/             # ESO for vault integration
├── kubernetes/
│   ├── argocd-apps/                  # Argo CD ApplicationSets
│   └── cluster-config/               # Namespace, RBAC, NetworkPolicy
├── scripts/
│   ├── bootstrap-cluster.sh          # New cluster setup
│   ├── install-argocd.sh
│   └── rotate-secrets.sh
└── docs/
    ├── ARCHITECTURE.md
    ├── DISASTER_RECOVERY.md
    └── ONBOARDING.md
```

## Architecture

```
┌──────────────────────────────────────────────────┐
│ AWS Region: ap-southeast-1                       │
│                                                   │
│  ┌──────────────────────────────────┐            │
│  │ Shared VPC                        │            │
│  │  - NAT Gateway                   │            │
│  │  - Transit Gateway               │            │
│  └──────────────────────────────────┘            │
│                                                   │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌──────┐│
│  │ DEV EKS │  │ QA EKS  │  │ STG EKS │  │PROD  ││
│  │ Cluster │  │ Cluster │  │ Cluster │  │EKS   ││
│  └─────────┘  └─────────┘  └─────────┘  └──────┘│
│                                                   │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌──────┐│
│  │ DEV RDS │  │ QA RDS  │  │ STG RDS │  │PROD  ││
│  │         │  │         │  │         │  │RDS   ││
│  └─────────┘  └─────────┘  └─────────┘  └──────┘│
│                                                   │
│  ┌──────────────────────────────────┐            │
│  │ Shared Services (1 cluster)      │            │
│  │  - Argo CD                       │            │
│  │  - Nexus                         │            │
│  │  - Prometheus + Grafana          │            │
│  │  - Loki + Tempo                  │            │
│  │  - Vault                         │            │
│  └──────────────────────────────────┘            │
└──────────────────────────────────────────────────┘
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.7
- kubectl >= 1.29
- Helm >= 3.14
- AWS account with admin access (initial bootstrap)

## Quick Start

### 1. Bootstrap a New Environment

```bash
cd terraform/environments/dev

terraform init
terraform plan
terraform apply
```

This provisions:
- VPC + subnets
- EKS cluster
- RDS PostgreSQL
- ElastiCache Redis
- S3 buckets
- IAM roles/policies

### 2. Configure kubectl

```bash
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name comp-proj-dev
```

### 3. Install Platform Services

```bash
# Argo CD
./scripts/install-argocd.sh dev

# Nexus
helm install nexus helm-charts/nexus -n nexus --create-namespace

# Reloader (auto-restart on config change)
helm install reloader helm-charts/reloader -n reloader-system --create-namespace

# Monitoring
helm install monitoring helm-charts/prometheus -n monitoring --create-namespace
```

### 4. Apply Kubernetes Cluster Config

```bash
kubectl apply -f kubernetes/cluster-config/
```

### 5. Bootstrap Argo CD with App-of-Apps

```bash
kubectl apply -f kubernetes/argocd-apps/app-of-apps.yaml
```

Argo CD now manages all application deployments via GitOps.

## Per-Environment Configuration

Each environment has its own Terraform state and configuration:

```bash
# DEV
cd terraform/environments/dev
terraform apply -var-file=dev.tfvars

# PROD (requires approval workflow)
cd terraform/environments/prod
terraform apply -var-file=prod.tfvars
```

Variables differ per environment:

| Variable | DEV | QA | STG | PROD |
|----------|-----|-----|-----|------|
| `cluster_size` | 2 nodes | 3 nodes | 5 nodes | 10 nodes |
| `instance_type` | t3.medium | t3.large | m5.xlarge | m5.2xlarge |
| `db_instance_class` | db.t3.small | db.t3.medium | db.r5.large | db.r5.xlarge |
| `multi_az` | false | false | true | true |
| `backup_retention` | 1 day | 7 days | 14 days | 30 days |

## Terraform State Management

State is stored in S3 with DynamoDB locking:

```hcl
# terraform/environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "comp-proj-tfstate"
    key            = "environments/dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "comp-proj-tfstate-lock"
    encrypt        = true
  }
}
```

## Helm Chart Updates

Platform services (Argo CD, Nexus, etc.) are updated via Helm:

```bash
# Update Argo CD to new version
helm upgrade argocd helm-charts/argocd \
  -n argocd \
  --values helm-charts/argocd/values-prod.yaml

# Verify
kubectl get pods -n argocd
```

## Disaster Recovery

### Backup Strategy

- **RDS**: Automated snapshots (retention varies by env)
- **EKS**: Cluster state in Git (this repo)
- **Argo CD**: App definitions in deploy repo
- **Nexus**: Volume snapshots daily
- **Vault**: Auto-unseal config in AWS KMS

### Recovery Time Objectives

| Component | RTO | RPO |
|-----------|-----|-----|
| EKS cluster | 30 min | N/A (stateless) |
| RDS database | 1 hour | 5 min (PITR) |
| Application config | 15 min | 0 (in Git) |
| Secrets | 30 min | 0 (Vault) |

See `docs/DISASTER_RECOVERY.md` for detailed runbooks.

## Cost Optimization

- Spot instances for non-prod (60% savings)
- Auto-scaling based on metrics
- Scheduled shutdown of dev/qa overnight
- Reserved instances for prod

Estimated monthly cost (ap-southeast-1):

| Env | EKS | RDS | Total |
|-----|-----|-----|-------|
| DEV | $150 | $50 | ~$250 |
| QA | $250 | $80 | ~$400 |
| STG | $500 | $200 | ~$800 |
| PROD | $1000 | $500 | ~$1800 |
| Shared | $300 | - | ~$400 |

## Security

- All resources tagged for compliance
- Network policies enforced
- Pod Security Standards: restricted
- Encryption at rest and in transit
- IAM roles for service accounts (IRSA)
- VPC flow logs enabled
- AWS GuardDuty enabled

## CI/CD for Infrastructure

```
PR opened → terraform plan (in CI)
         → review plan output
         → 2 approvers required
         → merge to main
         → terraform apply (manual trigger for prod)
```

## Required Secrets (GitHub)

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | For Terraform |
| `AWS_SECRET_ACCESS_KEY` | For Terraform |
| `TF_API_TOKEN` | Terraform Cloud (if used) |

## Onboarding New Service

When a new service joins the platform:

1. Create namespace in cluster config
2. Add NetworkPolicy
3. Add RBAC (ServiceAccount + Role)
4. Add Argo CD ApplicationSet entry
5. Provision RDS/Redis if needed
6. Document in `docs/services/<service-name>.md`

See `docs/ONBOARDING.md` for full checklist.

## Standards

- Terraform: follow [Terraform style guide](https://www.terraform.io/docs/language/syntax/style.html)
- Helm: pin chart versions, use `--atomic` flag
- Kubernetes: PodSecurity admission, NetworkPolicies mandatory
- Tagging: cost center, environment, owner, project

## Support

- **Issues**: open in this repo
- **Slack**: `#infrastructure`
- **On-call**: PagerDuty rotation
- **Owner**: `@comp/sre-team`

## License

Internal use only — COMP.