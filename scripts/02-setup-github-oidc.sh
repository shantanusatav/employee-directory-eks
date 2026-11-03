#!/bin/bash
# Run on the EC2 instance. Creates:
#   1. GitHub OIDC identity provider in IAM
#   2. IAM role "github-actions-ecr-role" that ONLY this repo's main branch can assume
#   3. A policy that lets that role push images to the employee-directory ECR repo only
set -e

GITHUB_USER="shantanusatav"
GITHUB_REPO="employee-directory-eks"
REGION="ap-south-1"
ECR_REPO="employee-directory"
ROLE_NAME="github-actions-ecr-role"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS account: $ACCOUNT_ID"

echo ">>> Creating GitHub OIDC provider (ignore 'EntityAlreadyExists' error)"
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 || true

cat > /tmp/trust.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike":   { "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USER}/${GITHUB_REPO}:ref:refs/heads/main" }
    }
  }]
}
EOF

cat > /tmp/ecr-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": "ecr:GetAuthorizationToken", "Resource": "*" },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload", "ecr:PutImage"
      ],
      "Resource": "arn:aws:ecr:${REGION}:${ACCOUNT_ID}:repository/${ECR_REPO}"
    }
  ]
}
EOF

echo ">>> Creating IAM role $ROLE_NAME"
aws iam create-role --role-name "$ROLE_NAME" \
  --assume-role-policy-document file:///tmp/trust.json || \
aws iam update-assume-role-policy --role-name "$ROLE_NAME" \
  --policy-document file:///tmp/trust.json

aws iam put-role-policy --role-name "$ROLE_NAME" \
  --policy-name ecr-push-only --policy-document file:///tmp/ecr-policy.json

echo ""
echo "DONE. Add this as a GitHub repository VARIABLE named AWS_ROLE_ARN:"
echo "  arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
