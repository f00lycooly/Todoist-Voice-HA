#!/bin/bash
# Initialize git repository

set -e

echo "🔧 Initializing Git repository..."

git init
git add .
git commit -m "Initial commit: Todoist Voice HA project structure"

echo "✅ Git repository initialized"
echo ""
echo "Next steps:"
echo "1. Create repository on GitHub"
echo "2. git remote add origin https://github.com/YOUR-USERNAME/Todoist-Voice-HA.git"
echo "3. git push -u origin main"
