# comp-proj

Per-project config for the `comp-proj` project.

- `common-config.json` — company / project / state backend coordinates.
- `configs/config.json` — shared + per-env catalog inputs.
  Edit env values (cidr, tags, …) here. The `infra-request`
  workflow merges `shared` + `envs.<env>` at pipeline time.
- `slots/` — created by the pipeline when a catalog is applied.
  Holds the rendered catalog + the saved tfplan. Don't edit by hand.

## Bootstrap (one-time, after this PR merges)

State backend resources are not managed by Terraform here —
create them once with the AWS CLI:

```bash
aws s3api create-bucket --bucket comp-proj-tfstate \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1
aws s3api put-bucket-versioning --bucket comp-proj-tfstate \
  --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name comp-proj-tfstate-lock \
  --region ap-southeast-1 \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```
