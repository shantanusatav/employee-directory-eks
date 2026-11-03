#!/bin/bash
# Run on the Ubuntu EC2 instance: installs Docker, AWS CLI v2, kubectl, eksctl, git, python
set -e

echo ">>> Updating packages"
sudo apt-get update -y
sudo apt-get install -y git unzip curl python3-pip python3-venv

echo ">>> Installing Docker"
sudo apt-get install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

echo ">>> Installing AWS CLI v2"
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q -o awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip

echo ">>> Installing kubectl"
KVER=$(curl -sL https://dl.k8s.io/release/stable.txt)
curl -sSLO "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo ">>> Installing eksctl"
curl -sSL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin/

echo ""
echo ">>> Versions:"
docker --version
aws --version
kubectl version --client
eksctl version
echo ""
echo "DONE. Now run:  newgrp docker   (or log out and SSH in again) so docker works without sudo."
