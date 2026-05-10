# 01 — AWS ↔ GitHub Actions Access

How to give the GitHub Actions in **this repo** permission to assume an
IAM role in your AWS account, so `infra-provision` can run terraform
without long-lived AWS keys.

This is **one-time per AWS account**. Once it's set up, every workflow
in `comp-proj-assignment/scg-asgn-infra` can assume the role via OIDC.

## What you'll create

| Resource | Why |
|---|---|
| OIDC identity provider for `token.actions.githubusercontent.com` | Lets AWS verify GitHub Actions tokens |
| IAM role `<ROLE_NAME>` | The role workflows assume; trust policy scoped to this repo |
| Attached managed policy (default `AdministratorAccess`) | What the role can do once assumed — tighten this for prod |

## Prerequisites

- [ ] `aws` CLI logged in as an admin in the **target** AWS account
      (`aws sts get-caller-identity` shows the right account).
- [ ] `jq` installed.
- [ ] You know the GitHub `<owner>/<repo>` you want to grant access to.

## Run it

```bash
make github-access \
  GH_REPO=comp-proj-assignment/scg-asgn-infra \
  ROLE_NAME=comp-proj-infra-deployer
```

Optional — narrower policy than AdministratorAccess:

```bash
make github-access \
  GH_REPO=comp-proj-assignment/scg-asgn-infra \
  ROLE_NAME=comp-proj-infra-deployer \
  POLICY_ARN=arn:aws:iam::aws:policy/PowerUserAccess
```

The script is **idempotent** — re-running just refreshes the trust
policy and re-attaches the managed policy.

### What gets printed

```
Account:    123456789012
GH repo:    comp-proj-assignment/scg-asgn-infra
Role:       comp-proj-infra-deployer
Policy:     arn:aws:iam::aws:policy/AdministratorAccess

→ OIDC provider arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
  ✓ created
→ IAM role comp-proj-infra-deployer
  ✓ created
→ attach arn:aws:iam::aws:policy/AdministratorAccess
  ✓ attached

✓ Done.

Set the repo variable in GitHub:
  Settings → Secrets and variables → Actions → Variables tab
  Name:  AWS_ROLE_ARN
  Value: arn:aws:iam::123456789012:role/comp-proj-infra-deployer
```

## Wire it into GitHub

1. Go to: `https://github.com/<owner>/<repo>/settings/variables/actions`
2. **Variables** tab (NOT Secrets).
3. **New repository variable** → Name: `AWS_ROLE_ARN`, Value: the ARN printed above.

`infra-provision` now picks it up and assumes the role via OIDC.

## How the trust is scoped

The trust policy uses `StringLike` on the OIDC token's `sub` claim:

```
repo:<GH_REPO>:*
```

That means **any branch, any workflow** in the repo can assume the role
(but no other repo). To narrow further (e.g. only `main`, only specific
environments), edit `tools/aws-github-access.sh` and adjust the `sub`
string — common patterns:

| Match | Sub string |
|---|---|
| Any branch | `repo:owner/repo:*` |
| Only `main` branch | `repo:owner/repo:ref:refs/heads/main` |
| Only `prod-approve` env | `repo:owner/repo:environment:prod-approve` |

## Verifying it works

After setting the repo variable, run any small workflow:

- Actions → **infra-provision** → leave `slot` blank, pick `env=nonprod`,
  `action=create`. The first job (`plan`) will:
  1. Pass the new `Verify AWS_ROLE_ARN is set` check.
  2. Successfully assume the role via OIDC.
  3. Run `terraform init` against your S3 backend.

If the OIDC step fails with *"Not authorized to perform sts:AssumeRoleWithWebIdentity"*,
the trust policy doesn't match — usually the `GH_REPO` you passed
doesn't match the actual repo identifier. Re-run `make github-access`
with the exact `<owner>/<repo>` you see in your repo URL.

## Tearing it down

```bash
make github-access-teardown ROLE_NAME=comp-proj-infra-deployer
```

This detaches all policies and deletes the role. The OIDC provider is
**not** removed — it may be shared with other roles in the same
account. The script prints the command to remove it manually if you
really want to.

## Why this lives in a Makefile, not Terraform

Bootstrap problem: managing the OIDC trust *with terraform* requires
AWS credentials *that come from* the OIDC trust. Chicken-and-egg.
Bootstrap with the AWS CLI as a human admin, then everything else
flows through the OIDC role.
