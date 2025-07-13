#!/bin/bash
# Test Home Assistant integration locally

set -e

echo "🏠 Testing Home Assistant Integration"
echo "===================================="

# Check if HA config directory exists
HA_CONFIG="${HA_CONFIG_DIR:-/config}"
if [ ! -d "$HA_CONFIG" ]; then
    HA_CONFIG="$HOME/.homeassistant"
fi

if [ ! -d "$HA_CONFIG" ]; then
    echo "❌ Home Assistant config directory not found"
    echo "Set HA_CONFIG_DIR environment variable or install HA locally"
    exit 1
fi

echo "📁 Using HA config directory: $HA_CONFIG"

# Copy integration to HA
echo "📋 Installing integration to Home Assistant..."
mkdir -p "$HA_CONFIG/custom_components"
cp -r custom_components/todoist_voice_ha_integration "$HA_CONFIG/custom_components/"

echo "✅ Integration copied to $HA_CONFIG/custom_components/"
echo ""
echo "📝 Next steps:"
echo "1. Restart Home Assistant"
echo "2. Go to Settings → Integrations"
echo "3. Add 'Todoist Voice HA Integration'"
echo "4. Configure with add-on URL: http://localhost:8080"
