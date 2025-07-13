#!/bin/bash
# manual-first-push.sh - Create the GHCR package manually first

set -e

echo "🔧 MANUAL FIRST PUSH TO GHCR"
echo "============================"

# Check if we have docker and git
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "❌ Git is required but not installed"; exit 1; }

echo "1. 🏗️ Building image locally..."
docker build -t ghcr.io/f00lycooly/todoist-voice-ha:latest .
echo "✅ Build successful!"

echo ""
echo "2. 🔑 Logging in to GHCR..."
echo "You'll need to create a Personal Access Token (PAT) with 'write:packages' permission"
echo "Go to: https://github.com/settings/tokens"
echo "Create a token with these scopes:"
echo "  ✅ write:packages"
echo "  ✅ read:packages"
echo "  ✅ repo (if repository is private)"
echo ""

read -p "Enter your GitHub username: " GITHUB_USERNAME
read -s -p "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
echo ""

echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin

echo ""
echo "3. 📤 Pushing image..."
docker push ghcr.io/f00lycooly/todoist-voice-ha:latest

echo ""
echo "4. 🔓 Making package public..."
curl -L \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/user/packages/container/todoist-voice-ha \
  -d '{"visibility":"public"}' && echo "✅ Package made public" || echo "⚠️ Could not change visibility (may need manual action)"

echo ""
echo "🎉 SUCCESS! Package created and should now be public"
echo ""
echo "📋 Next steps:"
echo "1. Go to https://github.com/f00lycooly?tab=packages"
echo "2. Verify the 'todoist-voice-ha' package is listed and public"
echo "3. Now GitHub Actions should work for future pushes"
echo ""
echo "🧪 Test the public image:"
echo "docker pull ghcr.io/f00lycooly/todoist-voice-ha:latest"