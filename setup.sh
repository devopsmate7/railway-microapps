#!/bin/bash

# Railway Microapps - EC2 Setup Script
# Run this on EC2 instance: bash setup.sh
# This installs all required tools for deployment

echo "🚂 Railway Microapps - EC2 Setup"
echo "================================"

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install unzip (needed for AWS CLI v2)
echo "📦 Installing unzip..."
sudo apt install -y unzip

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
echo ""

# Check AWS CLI
if command -v aws &> /dev/null; then
    echo "✅ AWS CLI: $(aws --version)"
else
    echo "❌ AWS CLI: NOT INSTALLED"
fi

# Check Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker: $(docker --version)"
else
    echo "❌ Docker: NOT INSTALLED"
fi

# Check kubectl
if command -v kubectl &> /dev/null; then
    echo "✅ kubectl: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
else
    echo "❌ kubectl: NOT INSTALLED"
fi

# Check git
if command -v git &> /dev/null; then
    echo "✅ git: $(git --version)"
else
    echo "❌ git: NOT INSTALLED"
fi

# Check curl
if command -v curl &> /dev/null; then
    echo "✅ curl: $(curl --version | head -1)"
else
    echo "❌ curl: NOT INSTALLED"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. If any tools show ❌, run setup.sh again"
echo "2. Configure AWS credentials: aws configure"
echo "3. Add your user to docker group: sudo usermod -aG docker \$USER && newgrp docker"
echo "4. Verify docker works: docker ps"
echo "5. Follow DEPLOYMENT-GUIDE.html for setup instructions"
echo ""
