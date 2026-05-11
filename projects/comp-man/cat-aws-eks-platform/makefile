create-gp3-sc:
	kubectl apply -f ./gp3-storageclass.yaml
	@echo
	@echo "Verify:  kubectl get sc"

# aws eks describe-cluster --name comp-man-eks-platform-np --region ap-southeast-1 --query 'cluster.identity.oidc.issuer' --output text

#   kubectl -n kube-system get sa ebs-csi-controller-sa -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'; echo 

#   arn:aws:iam::340741165554:role/AmazonEKSPodIdentityAmazonEBSCSIDriverRole