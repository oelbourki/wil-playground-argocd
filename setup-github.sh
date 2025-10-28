#!/bin/bash

# Setup script for pushing wil-playground-argocd to GitHub
# ========================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Wil's Playground ArgoCD Setup${NC}"
echo "================================="
echo ""

# Initialize git if not already done
if [ ! -d .git ]; then
    echo -e "${BLUE}Initializing git repository...${NC}"
    git init
    git add .
    git commit -m "Initial commit: Wil's playground manifests"
fi

# Check if git is configured
if ! git config user.name >/dev/null 2>&1; then
    echo -e "${YELLOW}Git user not configured. Please run:${NC}"
    echo "git config --global user.name 'Your Name'"
    echo "git config --global user.email 'your.email@example.com'"
    exit 1
fi

# Get GitHub repository URL
echo -e "${YELLOW}Enter your GitHub repository URL for wil-playground:${NC}"
echo "Example: https://github.com/Florian-A/wil-playground-argocd.git"
echo "Make sure the repository includes your group member's login in the name (e.g., agi-wil-playground)"
read -p "Repository URL: " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo -e "${RED}Repository URL is required${NC}"
    exit 1
fi

# Add remote origin
echo -e "${BLUE}Adding remote origin...${NC}"
git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"

# Push to GitHub
echo -e "${BLUE}Pushing to GitHub...${NC}"
git push -u origin master || git push -u origin main

echo ""
echo -e "${GREEN}Repository setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Update the repository URL in p3/confs/dev/app.yaml to:"
echo "   $REPO_URL"
echo "2. Update the path in p3/confs/dev/app.yaml to: '.' or 'manifest'"
echo "3. Run 'make up' in p3 directory to deploy with ArgoCD"
echo ""
echo "Repository URL: $REPO_URL"

