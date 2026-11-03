#!/bin/bash
# Run on EC2 inside the repo folder: puts your real AWS account ID into k8s/deployment.yaml
set -e
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
sed -i "s|AWS_ACCOUNT_ID|${ACCOUNT_ID}|" k8s/deployment.yaml
grep "image:" k8s/deployment.yaml
