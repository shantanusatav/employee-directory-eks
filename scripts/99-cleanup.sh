#!/bin/bash
# Run AFTER your demo/viva to stop AWS charges. EKS costs money every hour it runs.
set -e
REGION="ap-southeast-2"

echo ">>> Deleting Argo CD app and Kubernetes resources (removes the LoadBalancer)"
kubectl delete -f argocd/application.yaml --ignore-not-found
kubectl delete -f k8s/ --ignore-not-found
kubectl delete namespace argocd --ignore-not-found   # removes the Argo CD load balancer
sleep 60

echo ">>> Deleting EKS cluster (~10-15 min)"
eksctl delete cluster --name employee-cluster --region "$REGION"

echo ">>> Deleting ECR repository and images"
aws ecr delete-repository --repository-name employee-directory --region "$REGION" --force

echo ""
echo "Now go to the EC2 console and TERMINATE your EC2 instance too."
