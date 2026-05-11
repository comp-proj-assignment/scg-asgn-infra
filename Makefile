# Two groups of targets:
#
#   PROJECT-scoped (need PROJECT=<folder under projects/>):
#     bootstrap         Create S3 bucket + DynamoDB lock table for PROJECT
#     bootstrap-show    Print the planned actions without running them
#     teardown          Delete the backend (asks for confirmation)
#
#   ACCOUNT-scoped (need GH_REPO + ROLE_NAME, see template/docs/01_AWS_GITHUB_ACCESS.md):
#     github-access            Set up OIDC trust + IAM role for GitHub Actions
#     github-access-teardown   Detach + delete the IAM role
#
# Examples:
#   make bootstrap PROJECT=comp-proj
#   make github-access GH_REPO=comp-proj-assignment/scg-asgn-infra ROLE_NAME=comp-proj-infra-deployer

SHELL        := /bin/bash
PROJECTS_DIR := projects

# ── PROJECT enforcement: only required when a PROJECT-scoped target runs ──
PROJECT_TARGETS := bootstrap bootstrap-show bootstrap-bucket bootstrap-lock-table teardown
ifneq ($(filter $(PROJECT_TARGETS),$(MAKECMDGOALS)),)
  ifeq ($(strip $(PROJECT)),)
    $(error PROJECT is required, e.g. `make bootstrap PROJECT=comp-proj`)
  endif

  PROJECT_DIR := $(PROJECTS_DIR)/$(PROJECT)
  COMMON      := $(PROJECT_DIR)/common-config.json

  ifeq ($(wildcard $(COMMON)),)
    $(error $(COMMON) not found — run the project-init workflow first and merge the PR)
  endif

  BUCKET     := $(shell jq -r .remote_state.bucket     $(COMMON))
  LOCK_TABLE := $(shell jq -r .remote_state.lock_table $(COMMON))
  REGION     := $(shell jq -r .remote_state.region     $(COMMON))
endif

.PHONY: help \
        bootstrap bootstrap-show bootstrap-bucket bootstrap-lock-table teardown \
        github-access github-access-teardown

help:
	@echo "PROJECT-scoped (need PROJECT=<name>):"
	@echo "  bootstrap         Create S3 bucket + DynamoDB lock table"
	@echo "  bootstrap-show    Dry-run: print what would happen"
	@echo "  teardown          Delete the backend (asks)"
	@echo ""
	@echo "ACCOUNT-scoped (GitHub-AWS OIDC trust):"
	@echo "  github-access            Set up OIDC + IAM role"
	@echo "    GH_REPO=<owner>/<repo>"
	@echo "    ROLE_NAME=<role>"
	@echo "    POLICY_ARN=<arn>      (optional, default AdministratorAccess)"
	@echo "  github-access-teardown   Detach policies + delete role"
	@echo "    ROLE_NAME=<role>"
	@echo ""
	@echo "Requires: aws CLI (logged in), jq."
	@echo ""
	@echo "Approval gate: infra-provision uses trstringer/manual-approval@v1."
	@echo "  Optional repo variable APPROVERS='alice,bob' (comma-separated)."
	@echo "  If unset, falls back to whoever triggered the workflow run."
	@echo "  No GitHub Environments setup needed."

bootstrap-show:
	@echo "Project:    $(PROJECT)"
	@echo "Region:     $(REGION)"
	@echo "Bucket:     $(BUCKET)"
	@echo "Lock table: $(LOCK_TABLE)"

bootstrap: bootstrap-bucket bootstrap-lock-table
	@echo ""
	@echo "✓ Bootstrap complete for $(PROJECT)"
	@echo "  bucket     = $(BUCKET) (region $(REGION))"
	@echo "  lock_table = $(LOCK_TABLE)"

bootstrap-bucket:
	@echo "→ S3 bucket $(BUCKET) in $(REGION)"
	@if aws s3api head-bucket --bucket $(BUCKET) >/dev/null 2>&1; then \
		echo "  exists, skipping"; \
	else \
		if [ "$(REGION)" = "us-east-1" ]; then \
			aws s3api create-bucket --bucket $(BUCKET) --region us-east-1; \
		else \
			aws s3api create-bucket --bucket $(BUCKET) --region $(REGION) \
				--create-bucket-configuration LocationConstraint=$(REGION); \
		fi; \
		aws s3api put-bucket-versioning --bucket $(BUCKET) \
			--versioning-configuration Status=Enabled; \
		aws s3api put-public-access-block --bucket $(BUCKET) \
			--public-access-block-configuration \
			  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true; \
		aws s3api put-bucket-encryption --bucket $(BUCKET) \
			--server-side-encryption-configuration \
			  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'; \
		echo "  ✓ created (versioning on, public access blocked, SSE-S3)"; \
	fi

bootstrap-lock-table:
	@echo "→ DynamoDB table $(LOCK_TABLE) in $(REGION)"
	@if aws dynamodb describe-table --table-name $(LOCK_TABLE) --region $(REGION) >/dev/null 2>&1; then \
		echo "  exists, skipping"; \
	else \
		aws dynamodb create-table --table-name $(LOCK_TABLE) --region $(REGION) \
			--attribute-definitions AttributeName=LockID,AttributeType=S \
			--key-schema AttributeName=LockID,KeyType=HASH \
			--billing-mode PAY_PER_REQUEST >/dev/null; \
		aws dynamodb wait table-exists --table-name $(LOCK_TABLE) --region $(REGION); \
		echo "  ✓ created"; \
	fi

teardown:
	@echo "DANGER: this deletes the Terraform state backend for $(PROJECT)."
	@echo "  bucket     = $(BUCKET)"
	@echo "  lock_table = $(LOCK_TABLE)"
	@read -p "Type the project name to confirm: " confirm && \
		[ "$$confirm" = "$(PROJECT)" ] || (echo "aborted"; exit 1)
	-aws s3 rm s3://$(BUCKET) --recursive
	-aws s3api delete-bucket --bucket $(BUCKET) --region $(REGION)
	-aws dynamodb delete-table --table-name $(LOCK_TABLE) --region $(REGION)

# ── GitHub-AWS OIDC bootstrap ────────────────────────────────────────────
github-access:
	@[ -n "$(GH_REPO)" ]   || (echo "GH_REPO=<owner>/<repo> required" >&2; exit 1)
	@[ -n "$(ROLE_NAME)" ] || (echo "ROLE_NAME=<role> required" >&2; exit 1)
	GH_REPO="$(GH_REPO)" \
	ROLE_NAME="$(ROLE_NAME)" \
	POLICY_ARN="$(POLICY_ARN)" \
	  bash template/tools/aws-github-access.sh

github-access-teardown:
	@[ -n "$(ROLE_NAME)" ] || (echo "ROLE_NAME=<role> required" >&2; exit 1)
	ROLE_NAME="$(ROLE_NAME)" bash template/tools/aws-github-access-teardown.sh
