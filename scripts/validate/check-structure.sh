#!/bin/bash
# Validate project structure

echo "🔍 Checking project structure..."

REQUIRED_FILES=(
    "README.md"
    "LICENSE"
    "hacs.json"
    "addon/config.yaml"
    "addon/package.json"
    "custom_components/todoist_voice_ha_integration/manifest.json"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Missing: $file"
    fi
done

echo "✅ Structure check complete"
