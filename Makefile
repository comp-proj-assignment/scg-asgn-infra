# Bootstraps the Terraform remote-state backend (S3 + DynamoDB) for a
# project. Reads projects/<PROJECT>/common-config.json — which is
# created by the `project-init` workflow — and creates the resources
# named there if they don't already exist.
#
# Usage:
#   make bootstrap PROJECT=comp-proj
#   make bootstrap-show PROJECT=comp-proj   # dry-run: print what would happen
#   make teardown PROJECT=comp-proj         # delete bucket + table (asks)

SHELL        := /bin/bash
PROJECTS_DIR := projects
PROJECT      ?=

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

.PHONY: help bootstrap bootstrap-show bootstrap-bucket bootstrap-lock-table teardown

help:
	@echo "Targets:"
	@echo "  bootstrap         Create S3 bucket + DynamoDB lock table for PROJECT"
	@echo "  bootstrap-show    Print the planned actions without running them"
	@echo "  teardown          Delete the backend (asks for confirmation)"
	@echo ""
	@echo "Requires: aws CLI logged in, jq, PROJECT=<folder under projects/>"

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
