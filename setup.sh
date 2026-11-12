#!/bin/bash

# Railway Microapps - EC2 Setup Script
# Run this on EC2 instance: bash setup.sh
# This installs all required tools for deployment

set -e  # Exit on error
FAILED_TOOLS=()  # Track failed installations

echo "🚂 Railway Microapps - EC2 Setup"
echo "================================"
echo ""

# Function to check if command exists
check_installed() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Update system
echo "📦 Step 1: Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
echo "✅ System updated"
echo ""

# Install prerequisites
echo "📦 Step 2: Installing prerequisites (curl, unzip, git)..."
sudo apt-get install -y -qq curl unzip git wget
echo "✅ Prerequisites installed"
echo ""

# Install Docker
echo "📦 Step 3: Installing Docker..."
if check_installed docker; then
    echo "✅ Docker already installed"
else
    sudo apt-get install -y -qq docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    # Switch group for the current script run (non-interactive) to avoid docker.sock permission errors
    newgrp docker -- docker ps >/dev/null 2>&1 || true
    echo "✅ Docker installed"
fi
echo ""

# Install kubectl
echo "📦 Step 4: Installing kubectl (v1.29.0)..."
if check_installed kubectl; then
    echo "✅ kubectl already installed"
else
    KUBECTL_VERSION="1.29.0"
    KUBECTL_URL="https://s3.us-west-2.amazonaws.com/amazon-eks/${KUBECTL_VERSION}/2024-01-04/bin/linux/amd64/kubectl"
    
    echo "   Downloading kubectl from ${KUBECTL_URL}..."
    curl -L -s -o /tmp/kubectl "$KUBECTL_URL"
    
    if [ ! -f /tmp/kubectl ]; then
        echo "❌ Failed to download kubectl"
        FAILED_TOOLS+=("kubectl")
    else
        chmod +x /tmp/kubectl
        sudo mv /tmp/kubectl /usr/local/bin/kubectl
        echo "✅ kubectl installed"
    fi
fi
echo ""

# Install AWS CLI v2
echo "📦 Step 5: Installing AWS CLI v2..."
if check_installed aws; then
    echo "✅ AWS CLI already installed"
else
    echo "   Downloading AWS CLI v2..."
    cd /tmp
    
    # Download AWS CLI v2
    curl -L -s -o "awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
    
    if [ ! -f /tmp/awscliv2.zip ]; then
        echo "❌ Failed to download AWS CLI v2"
        FAILED_TOOLS+=("aws-cli")
    else
        # Extract and install
        unzip -q -o awscliv2.zip
        
        if [ -d /tmp/aws ]; then
            sudo /tmp/aws/install --update
            echo "✅ AWS CLI v2 installed"
        else
            echo "❌ Failed to extract AWS CLI v2"
            FAILED_TOOLS+=("aws-cli")
        fi
    fi
    
    # Cleanup
    rm -f /tmp/awscliv2.zip
    rm -rf /tmp/aws
    cd - > /dev/null
fi
echo ""

# Verify all installations
echo "================================"
echo "✅ VERIFICATION RESULTS:"
echo "================================"
echo ""

INSTALLED_COUNT=0
FAILED_COUNT=0

# Check AWS CLI
echo -n "AWS CLI v2:        "
if check_installed aws; then
    echo "✅ $(aws --version 2>&1 | cut -d' ' -f1-2)"
    ((INSTALLED_COUNT++))
else
    echo "❌ NOT INSTALLED"
    ((FAILED_COUNT++))
fi

# Check Docker
echo -n "Docker:            "
if check_installed docker; then
    echo "✅ $(docker --version 2>&1 | cut -d' ' -f3-)"
    ((INSTALLED_COUNT++))
else
    echo "❌ NOT INSTALLED"
    ((FAILED_COUNT++))
fi

# Check kubectl
echo -n "kubectl:           "
if check_installed kubectl; then
    echo "✅ $(kubectl version --client --short 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')"
    ((INSTALLED_COUNT++))
else
    echo "❌ NOT INSTALLED"
    ((FAILED_COUNT++))
fi

# Check git
echo -n "git:               "
if check_installed git; then
    echo "✅ $(git --version 2>&1 | cut -d' ' -f3)"
    ((INSTALLED_COUNT++))
else
    echo "❌ NOT INSTALLED"
    ((FAILED_COUNT++))
fi

# Check curl
echo -n "curl:              "
if check_installed curl; then
    echo "✅ $(curl --version 2>&1 | head -1 | cut -d' ' -f2)"
    ((INSTALLED_COUNT++))
else
    echo "❌ NOT INSTALLED"
    ((FAILED_COUNT++))
fi

echo ""
echo "================================"

if [ $FAILED_COUNT -eq 0 ]; then
    echo "🎉 SUCCESS! All tools installed! ($INSTALLED_COUNT/5)"
    echo ""
    echo "📝 NEXT STEPS:"
    echo "1. NEW GROUP: newgrp docker"
    echo "2. TEST DOCKER: docker ps"
    echo "3. CONFIG AWS: aws configure"
    echo "4. VERIFY KUBECTL: kubectl version --client"
    echo "5. START DEPLOYMENT: Follow DEPLOYMENT-GUIDE.html"
else
    echo "⚠️  INCOMPLETE! ($INSTALLED_COUNT/5 installed)"
    echo ""
    echo "Failed tools:"
    for tool in "${FAILED_TOOLS[@]}"; do
        echo "  - $tool"
    done
    echo ""
    echo "Try running: bash setup.sh again"
fi

echo ""
