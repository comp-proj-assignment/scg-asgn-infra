# comp-proj-infra — Setup

Provisions AWS infrastructure (VPC today; EKS and IAM/IRSA are the
next catalogs). See `DEFINITION.md` for the catalog/slot pattern.

> **Phase 1 note:** Container images live on **public GHCR**
> (`ghcr.io/comp/{api,web}`), so no ECR catalog is needed yet. EKS
> nodes pull anonymously. Add a `cat-aws-ecr` catalog only when the
> images need to go private.

## Prerequisites

- [ ] AWS account, admin IAM user for the bootstrap (one-time)
- [ ] Terraform 1.7.5+ (`tfenv install 1.7.5`)
- [ ] `aws`, `jq` CLIs

## 1. Bootstrap the remote state backend (one-time, manual)

The `infra-request` workflow assumes an S3 bucket + DynamoDB lock
table already exist. Create them once with the AWS CLI — they cannot
be managed by Terraform that lives inside themselves.

Look up the names in `common-config.json`:

```bash
BUCKET=$(jq -r .remote_state.bucket common-config.json)
TABLE=$(jq -r .remote_state.lock_table common-config.json)
REGION=$(jq -r .remote_state.region common-config.json)

aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"
aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws dynamodb create-table --table-name "$TABLE" --region "$REGION" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## 2. Set up GitHub OIDC → AWS

The workflow uses `aws-actions/configure-aws-credentials` with OIDC,
not long-lived keys.

- [ ] Create an IAM OIDC provider for `token.actions.githubusercontent.com`
- [ ] Create role `comp-proj-infra-deployer` trusting that provider,
      scoped to `repo:comp/comp-proj-infra:*`
- [ ] Attach a policy that lets the role read/write the state bucket
      and create the resources catalogs need (start broad, tighten later)
- [ ] In the GitHub repo settings → **Variables**, set `AWS_ROLE_ARN`
      to the role's ARN

## 3. Configure GitHub environments for approval gates

The `apply` job uses `environment: ${{ inputs.env }}-approve` so a
human must approve before Terraform mutates anything.

- [ ] In repo Settings → Environments, create:
  - `nonprod-approve` — required reviewers: `@comp/sre-team`
  - `prod-approve` — required reviewers: `@comp/sre-team` + `@comp/release-managers`

## 4. Run your first catalog

Currently the only catalog is `cat-aws-vpc`. Run it from the GitHub UI:

- Actions → **infra-request** → Run workflow
  - catalog: `cat-aws-vpc`
  - env: `nonprod`
  - action: `create`

The workflow plans, uploads `tfplan` as an artifact, then waits for
your approval before applying. Approve in the **Environments** tab.

## 5. Add an EKS catalog (next milestone, not done yet)

The deploy repo expects an EKS cluster. Until a `cat-aws-eks` catalog
exists in `catalogs/`, you'll need to create the cluster manually
(`eksctl create cluster …`) and capture its kubeconfig.

When `cat-aws-eks` lands, also set up:
- IRSA role for the api ServiceAccount (`api-{dev,qa,staging,prod}` namespaces)
- IRSA role for the web ServiceAccount
- Both annotated on the ServiceAccounts in `comp-proj-app-demo-deployment/apps/*/base/service.yaml`

## You're done when

- [ ] `infra-request` ran end-to-end at least once for `nonprod`
- [ ] State files appear in the S3 bucket under `comp-proj/<slot>/<env>/terraform.tfstate`
- [ ] The next person can re-run the workflow without bootstrapping
