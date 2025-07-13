#!/bin/bash
# Package add-on for Home Assistant installation

set -e

echo "📦 Packaging Todoist Voice HA Add-on"
echo "===================================="

# Create dist directory
mkdir -p dist

# Create add-on archive
echo "🗜️  Creating add-on archive..."
tar -czf dist/todoist-voice-ha-addon.tar.gz \
    --exclude=node_modules \
    --exclude=.env* \
    --exclude=*.log \
    addon/

echo "✅ Add-on package created: dist/todoist-voice-ha-addon.tar.gz"
echo ""
echo "📋 Installation instructions:"
echo "1. Copy dist/todoist-voice-ha-addon.tar.gz to your HA machine"
echo "2. Extract to /addons/local/todoist-voice-ha/"
echo "3. Restart Home Assistant Supervisor"
echo "4. Install from Local Add-ons"
