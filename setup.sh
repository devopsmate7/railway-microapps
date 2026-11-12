#!/bin/bash

# Railway Microapps - EC2 Setup Script
# Run this on EC2 instance: bash setup.sh
# This installs all required tools for deployment

set -e  # Exit on any error

echo "🚂 Railway Microapps - EC2 Setup"
echo "================================"

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install AWS CLI v2
echo "📦 Installing AWS CLI v2..."
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
cd -
rm -rf /tmp/awscliv2.zip /tmp/aws

# Install Docker
echo "📦 Installing Docker..."
sudo apt install -y docker.io
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
echo "📦 Installing kubectl..."
curl -o /tmp/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.0/2024-01-04/bin/linux/amd64/kubectl
chmod +x /tmp/kubectl
sudo mv /tmp/kubectl /usr/local/bin/

# Install git
echo "📦 Installing git..."
sudo apt install -y git

# Install curl (usually comes with system, but ensure it)
echo "📦 Installing curl..."
sudo apt install -y curl

# Verify installations
echo ""
echo "✅ Verifying installations..."
echo "AWS CLI: $(aws --version)"
echo "Docker: $(docker --version)"
echo "kubectl: $(kubectl version --client --short)"
echo "git: $(git --version)"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Configure AWS credentials: aws configure"
echo "2. Clone railway-microapps: git clone https://github.com/devopsmate7/railway-microapps.git"
echo "3. Follow DEPLOYMENT-GUIDE.html for setup instructions"
echo ""
