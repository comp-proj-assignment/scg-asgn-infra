# comp-proj

Per-project config for the `comp-proj` project.

- `common-config.json` — company / project / state backend coordinates.
- `configs/config.json` — shared + per-env catalog inputs.
  Edit env values (cidr, tags, …) here. The `infra-request`
  workflow merges `shared` + `envs.<env>` at pipeline time.
- `slots/` — created by the pipeline when a catalog is applied.
  Holds the rendered catalog + the saved tfplan. Don't edit by hand.

## Bootstrap (one-time, after this PR merges)

State backend resources (S3 bucket + DynamoDB lock table) are
not managed by Terraform here. Create them once with the
repo Makefile:

```bash
# Pull main first so projects/comp-proj/common-config.json
# is on disk, then:
make bootstrap PROJECT=comp-proj
```

That reads `common-config.json` and creates:
- S3 bucket `comp-proj-tfstate` (versioned, encrypted, public-access blocked)
- DynamoDB table `comp-proj-tfstate-lock` (PAY_PER_REQUEST)

Re-running is safe — both checks skip if the resources exist.
