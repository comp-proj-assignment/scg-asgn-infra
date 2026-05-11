SHELL   := /bin/bash
CLUSTER := comp-man-eks-platform-np
REGION  := ap-southeast-1

# EBS CSI driver via EKS Pod Identity
EBS_CSI_ROLE_NAME := AmazonEKS_EBS_CSI_DriverRole
EBS_CSI_NS        := kube-system
EBS_CSI_SA        := ebs-csi-controller-sa

.PHONY: create-gp3-sc ebs-csi-pod-identity

create-gp3-sc:
	kubectl apply -f ./gp3-storageclass.yaml
	@echo
	@echo "Verify:  kubectl get sc"

# Switch the EBS CSI controller from IRSA to EKS Pod Identity:
#   1. Rewrite the role's trust policy to `pods.eks.amazonaws.com`
#   2. Drop the IRSA SA annotation (so the SDK doesn't go down the OIDC path)
#   3. Create the pod-identity association (kube-system/ebs-csi-controller-sa ↔ role)
#   4. Restart the controller deployment so it picks up new credentials
# Idempotent: re-running cleanly replaces the existing association.
ebs-csi-pod-identity:
	@echo "→ updating $(EBS_CSI_ROLE_NAME) trust policy to Pod Identity"
	aws iam update-assume-role-policy \
	  --role-name $(EBS_CSI_ROLE_NAME) \
	  --policy-document file://iam/ebs-csi-pod-identity-trust.json

	@echo "→ removing IRSA annotation from $(EBS_CSI_NS)/$(EBS_CSI_SA)"
	-kubectl -n $(EBS_CSI_NS) annotate sa $(EBS_CSI_SA) eks.amazonaws.com/role-arn- --overwrite

	@echo "→ deleting any prior pod-identity association for $(EBS_CSI_NS)/$(EBS_CSI_SA)"
	@for ID in $$(aws eks list-pod-identity-associations \
	    --cluster-name $(CLUSTER) --region $(REGION) \
	    --query "associations[?namespace=='$(EBS_CSI_NS)' && serviceAccount=='$(EBS_CSI_SA)'].associationId" \
	    --output text); do \
	  echo "  removing $$ID"; \
	  aws eks delete-pod-identity-association \
	    --cluster-name $(CLUSTER) --region $(REGION) \
	    --association-id $$ID >/dev/null; \
	done

	@echo "→ creating fresh pod-identity association"
	ROLE_ARN=$$(aws iam get-role --role-name $(EBS_CSI_ROLE_NAME) --query 'Role.Arn' --output text) ; \
	aws eks create-pod-identity-association \
	  --cluster-name $(CLUSTER) --region $(REGION) \
	  --namespace $(EBS_CSI_NS) --service-account $(EBS_CSI_SA) \
	  --role-arn "$$ROLE_ARN" >/dev/null

	@echo "→ restarting controller so it re-reads credentials"
	kubectl -n $(EBS_CSI_NS) rollout restart deployment ebs-csi-controller
	kubectl -n $(EBS_CSI_NS) rollout status  deployment ebs-csi-controller --timeout=120s

	@echo "✓ Done. Tail logs to confirm no more AccessDenied:"
	@echo "  kubectl -n $(EBS_CSI_NS) logs -l app=ebs-csi-controller -c csi-provisioner --tail=20"
