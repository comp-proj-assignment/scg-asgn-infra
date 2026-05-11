#!/usr/bin/env bash
# Tear down the OIDC IAM role created by aws-github-access.sh.
# Does NOT remove the OIDC provider (it may be used by other roles).
#
# Inputs (env vars):
#   ROLE_NAME   required.

set -euo pipefail

: "${ROLE_NAME:?ROLE_NAME=<role> required}"

echo "Detaching policies from ${ROLE_NAME}..."
aws iam list-attached-role-policies --role-name "${ROLE_NAME}" \
  --query 'AttachedPolicies[].PolicyArn' --output text \
  | tr '\t' '\n' | while read -r arn; do
      [ -z "$arn" ] && continue
      echo "  -- $arn"
      aws iam detach-role-policy --role-name "${ROLE_NAME}" --policy-arn "$arn"
    done

echo "Deleting inline policies (if any)..."
aws iam list-role-policies --role-name "${ROLE_NAME}" \
  --query 'PolicyNames[]' --output text \
  | tr '\t' '\n' | while read -r name; do
      [ -z "$name" ] && continue
      echo "  -- $name"
      aws iam delete-role-policy --role-name "${ROLE_NAME}" --policy-name "$name"
    done

echo "Deleting role ${ROLE_NAME}..."
aws iam delete-role --role-name "${ROLE_NAME}"
echo "✓ Done."
echo
echo "OIDC provider was NOT removed (it may be shared with other roles)."
echo "If you want to remove it too, run:"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "  aws iam delete-open-id-connect-provider \\"
echo "    --open-id-connect-provider-arn arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
