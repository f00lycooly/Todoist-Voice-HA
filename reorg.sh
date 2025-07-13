#!/bin/bash
# quick-reorganize.sh - Quick reorganization to standard HA add-on structure

set -e

echo "🚀 Quick Repository Reorganization"
echo "=================================="

# Take the best of both worlds:
# - config.yaml from addon/ (more complete - 1901 bytes)
# - Dockerfile from todoist-voice-ha/ (newer - 1470 bytes) 
# - build.yaml from todoist-voice-ha/ (newer format)
# - package.json from addon/ (more complete - 658 bytes)
# - src/ from todoist-voice-ha/ (most recent)

echo "Moving optimal files to root..."

# Move files to root (taking the best version of each)
cp addon/config.yaml ./
cp todoist-voice-ha/build.yaml ./
cp addon/package.json ./
cp todoist-voice-ha/Dockerfile ./
cp -r todoist-voice-ha/src ./

# Fix placeholder values in config.yaml
sed -i 's|{username}|f00lycooly|g' config.yaml
sed -i 's|{email}|your-email@example.com|g' config.yaml

# Update GitHub Actions to use root directory
sed -i 's|context: \./todoist-voice-ha|context: .|g' .github/workflows/build-addon.yml
sed -i 's|file: \./todoist-voice-ha/Dockerfile|file: ./Dockerfile|g' .github/workflows/build-addon.yml

echo "✅ Files reorganized!"
echo ""
echo "📁 Your root directory now has:"
ls -la *.yaml *.json Dockerfile src/ 2>/dev/null | head -10

echo ""
echo "🔥 Ready to build!"
echo "Next: git add . && git commit -m 'Reorganize to standard HA add-on structure' && git push"