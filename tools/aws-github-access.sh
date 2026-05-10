#!/usr/bin/env bash
# Bootstrap GitHub-Actions → AWS OIDC trust for this repo, idempotently.
# Creates (or refreshes) three things in the active AWS account:
#   1. OIDC identity provider for token.actions.githubusercontent.com
#   2. IAM role with a trust policy scoped to repo:<GH_REPO>:*
#   3. Attaches a managed policy (broad by default, tighten via POLICY_ARN)
#
# Prints the role ARN to set in GitHub Settings → Variables → AWS_ROLE_ARN.
#
# Inputs (env vars):
#   GH_REPO     required. e.g. "comp-proj-assignment/scg-asgn-infra"
#   ROLE_NAME   required. e.g. "comp-proj-infra-deployer"
#   POLICY_ARN  optional. default: AdministratorAccess

set -euo pipefail

: "${GH_REPO:?GH_REPO=<owner>/<repo> required (e.g. comp-proj-assignment/scg-asgn-infra)}"
: "${ROLE_NAME:?ROLE_NAME=<role> required (e.g. comp-proj-infra-deployer)}"
POLICY_ARN="${POLICY_ARN:-arn:aws:iam::aws:policy/AdministratorAccess}"

if ! command -v aws >/dev/null; then
  echo "aws CLI not found." >&2; exit 1
fi
if ! command -v jq >/dev/null; then
  echo "jq not found." >&2; exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

echo "Account:    ${ACCOUNT_ID}"
echo "GH repo:    ${GH_REPO}"
echo "Role:       ${ROLE_NAME}"
echo "Policy:     ${POLICY_ARN}"
echo

# ── 1. OIDC identity provider ────────────────────────────────────────────
echo "→ OIDC provider ${PROVIDER_ARN}"
if aws iam get-open-id-connect-provider \
     --open-id-connect-provider-arn "${PROVIDER_ARN}" >/dev/null 2>&1; then
  echo "  exists, skipping"
else
  aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 >/dev/null
  echo "  ✓ created"
fi

# ── 2. IAM role + trust policy ───────────────────────────────────────────
TRUST_POLICY=$(jq -n \
  --arg provider "${PROVIDER_ARN}" \
  --arg sub "repo:${GH_REPO}:*" \
  '{
     Version: "2012-10-17",
     Statement: [{
       Effect: "Allow",
       Principal: { Federated: $provider },
       Action: "sts:AssumeRoleWithWebIdentity",
       Condition: {
         StringEquals: { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
         StringLike:   { "token.actions.githubusercontent.com:sub": $sub }
       }
     }]
   }')

echo "→ IAM role ${ROLE_NAME}"
if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  echo "  exists, refreshing trust policy"
  aws iam update-assume-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-document "${TRUST_POLICY}" >/dev/null
else
  aws iam create-role \
    --role-name "${ROLE_NAME}" \
    --assume-role-policy-document "${TRUST_POLICY}" \
    --description "OIDC role for GitHub Actions in ${GH_REPO}" >/dev/null
  echo "  ✓ created"
fi

# ── 3. Attach policy (idempotent) ────────────────────────────────────────
echo "→ attach ${POLICY_ARN}"
aws iam attach-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-arn "${POLICY_ARN}" >/dev/null
echo "  ✓ attached"

echo
echo "✓ Done."
echo
echo "Set the repo variable in GitHub:"
echo "  Settings → Secrets and variables → Actions → Variables tab"
echo "  Name:  AWS_ROLE_ARN"
echo "  Value: ${ROLE_ARN}"
