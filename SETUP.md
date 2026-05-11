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

## Config layout

Two files, both committed:

- `common-config.json` — values shared across **every** environment
  and catalog (company, project, state backend coordinates).
- `configs/config.json` — single source for catalog inputs, with a
  `shared` block + per-env overrides under `envs.<name>`. The
  `infra-request` workflow merges these at pipeline time and feeds
  the result to terraform as a tfvars file. **Don't create
  `config/config-{env}.json` files** — they're rendered ephemerally
  into `.pipeline-tmp/` by the workflow and never committed.

To add a new env: add an entry under `envs` in `configs/config.json`
and add it to the `env` choice list in `infra-request.yml`.

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

Three workflows, run in order:

1. **`project-init`** (once per project) — scaffolds
   `projects/<company>-<project>/` with `common-config.json` and a
   project README.
2. **`infra-request`** (once per catalog instance, per project) — copies
   a catalog version into `projects/<project>/<catalog>-<service_name>/`
   and generates per-env tfvars inside it at
   `configs/config-nonprod.json` and `configs/config-prod.json`
   (both env files written in one go, from the catalog's
   `configs/config.json` template). Opens a PR. **No AWS calls.**
3. **`infra-provision`** (every time you want to apply or destroy) —
   takes the staged slot on `main`, picks an env at run time, plans,
   pauses for manual approval (issue created by
   `trstringer/manual-approval`), then applies. Pass `action=create`
   or `destroy`.

Walk-through for the existing `comp-proj` project + `cat-aws-vpc`:

- Actions → **infra-request** → Run workflow
  - project: `comp-proj`
  - catalog: `cat-aws-vpc`
  - version: `v1.0.0`
  - service_name: `demo`

  → opens a PR adding `projects/comp-proj/cat-aws-vpc-demo/` with
  both `configs/config-nonprod.json` and `configs/config-prod.json`.
  Review and merge.

- Actions → **infra-provision** → Run workflow
  - project: `comp-proj`
  - slot: (leave blank to auto-detect, or `cat-aws-vpc-demo`)
  - env: `nonprod`
  - action: `create`

  → comment `approved` on the issue the workflow opens. Apply runs.

  → plans, uploads `tfplan`, waits for approval in the Environments
  tab, then applies.

## 5. Add an EKS catalog (next milestone, not done yet)

The deploy repo expects an EKS cluster. Until a `cat-aws-eks` catalog
exists in `template/catalogs/`, you'll need to create the cluster manually
(`eksctl create cluster …`) and capture its kubeconfig.

When `cat-aws-eks` lands, also set up:
- IRSA role for the api ServiceAccount (`api-{dev,qa,staging,prod}` namespaces)
- IRSA role for the web ServiceAccount
- Both annotated on the ServiceAccounts in `comp-proj-app-demo-deployment/apps/*/base/service.yaml`

## You're done when

- [ ] `infra-request` ran end-to-end at least once for `nonprod`
- [ ] State files appear in the S3 bucket under `comp-proj/<slot>/<env>/terraform.tfstate`
- [ ] The next person can re-run the workflow without bootstrapping
